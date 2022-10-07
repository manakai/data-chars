use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;
use Web::Encoding;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;

my $DataSets = [
  {key => 'char', path => $RootPath->child ('intermediate/charrels')},
  {key => 'han', path => $RootPath->child ('intermediate/variants')},
];

binmode STDOUT, qw(:encoding(utf-8));
binmode STDERR, qw(:encoding(utf-8));

my $DataRoot = {};
for my $ds (@$DataSets) {
  my $path = $ds->{path}->child ('tbl-root.json');
  $DataRoot->{$ds->{key}} = json_bytes2perl $path->slurp;
}

{
  my $tables = {};
  for my $ds (@$DataSets) {
    my $path = $ds->{path}->child ('tbl-clusters.dat');
    $tables->{$ds->{key}} = $path->slurp;
  }
  sub cluster_index_from_tbl ($$$) {
    my $ds_key = $_[0];
    my $def = $_[1];

    my $offset = $def->{offset} + $_[2] * 3;
    if ($def->{offset_next} <= $offset) {
      return undef;
    }
    
    my $x = "\x00" . substr $tables->{$ds_key}, $offset, 3;
    return unpack ('L>', $x);
  } # cluster_index_from_tbl

  sub chars_from_tbl ($$$) {
    my $ds_key = shift;
    my $level = shift;
    my $index = shift;
    my $x = substr ((pack 'L>', $index), 1);
    my $length = length $tables->{$ds_key};
    my $chars = [];
    my @def = @{$DataRoot->{$ds_key}->{tables}};
    my $i = 0;
    while ($i < $length) {
      if ($x eq substr $tables->{$ds_key}, $i, 3) {
        while (@def and $def[0]->{offset_next} <= $i) {
          shift @def;
        }
        my $def = $def[0];
        if ($def->{level_key} ne $level) {
          #
        } elsif ($def->{type} eq 'unicode') {
          push @$chars, chr (($i - $def->{offset}) / 3 + $def->{unicode_offset});
        } elsif ($def->{type} eq 'unicode-suffix') {
          push @$chars, chr (($i - $def->{offset}) / 3 + $def->{unicode_offset}) . chr $def->{suffix};
        } else {
          die $def->{type};
        }
      }
      $i += 3;
    }
    return $chars;
  } # chars_from_tbl
}

{
  my $tables = {};
  for my $ds (@$DataSets) {
    my $path = $ds->{path}->child ('tbl-rels.dat');
    $tables->{$ds->{key}} = $path->slurp;
  }
  sub rels_from_tbl ($$) {
    my $ds_key = shift;
    my $char = shift;
    return [] if $char =~ /\x00/;
    my $bchar = "\x00" . (encode_web_utf8 $char) . "\x01";
    my $start = index $tables->{$ds_key}, $bchar;
    return [] if $start < 0;
    $start += length $bchar;
    my $end = index $tables->{$ds_key}, "\x00", $start;
    return [] if $end < 0; # broken
    my $r = substr $tables->{$ds_key}, $start, $end - $start;
    my $y = [split /\x01/, $r, -1];
    my $rels = [];
    while (@$y) {
      my $bc2 = shift @$y;
      next unless length $bc2; # at end or broken
      my $v2 = shift @$y; # undef if broken
      my $i2 = 0;
      my $l2 = length $v2;
      my $rr = [];
      while ($i2 < $l2) {
        my $v = (((unpack 'C', substr $v2, $i2, 1) & 0b01111111) << 7) +
                 ((unpack 'C', substr $v2, $i2 + 1, 1) & 0b01111111);
        push @$rr, [$ds_key, $v];
        $i2 += 2;
      }
      push @$rels, [(decode_web_utf8 $bc2), $rr];
    } # $y
    return $rels;
  } # rels_from_tbl
}

sub _ds_get_cluster ($$$) {
  my $ds_key = shift;
  my $level = shift;
  if (1 == length $_[0]) {
    my $cc = ord $_[0];
    my $def;
    for (@{$DataRoot->{$ds_key}->{tables}}) {
      if ($_->{level_key} eq $level and
          $_->{type} eq 'unicode' and
          $_->{unicode_offset} <= $cc and $cc < $_->{unicode_offset_next}) {
        $def = $_;
        last;
      }
    }

    if (defined $def) {
      my $index = cluster_index_from_tbl $ds_key, $def, $cc - $def->{unicode_offset};
      return $index ? {index => $index} : undef if defined $index;
    }
  }

  if (2 == length $_[0]) {
    my $cc1 = ord $_[0];
    my $cc2 = ord substr $_[0], 1;
    my $def;
    for (@{$DataRoot->{$ds_key}->{tables}}) {
      if ($_->{level_key} eq $level and
          $_->{type} eq 'unicode-suffix' and
          $_->{suffix} == $cc2 and
          $_->{unicode_offset} <= $cc1 and $cc1 < $_->{unicode_offset_next}) {
        $def = $_;
        last;
      }
    }

    if (defined $def) {
      my $index = cluster_index_from_tbl $ds_key, $def, $cc1 - $def->{unicode_offset};
      return $index ? {index => $index} : undef if defined $index;
    }
  }

  {
    my $index = $DataRoot->{$ds_key}->{others}->{$level}->{$_[0]};
    return undef unless $index;

    return {index => $index};
  }
} # _ds_get_cluster

sub get_cluster ($$) {
  my $cluster = {indexes => {}};
  for my $ds (@$DataSets) {
    my $r = _ds_get_cluster ($ds->{key}, $_[0], $_[1]);
    $cluster->{indexes}->{$ds->{key}} = $r->{index} if defined $r;
  }
  return $cluster;
} # get_cluster

sub get_chars ($$$) {
  my ($level, $cluster, $ds_key) = @_;

  my $chars = [];
  my $index = $cluster->{indexes}->{$ds_key} // return $chars;

  for (keys %{$DataRoot->{$ds_key}->{others}->{$level}}) {
    if ($DataRoot->{$ds_key}->{others}->{$level}->{$_} == $index) {
      push @$chars, $_;
    }
  }

  push @$chars, @{chars_from_tbl $ds_key, $level, $index};

  return $chars;
} # get_chars

sub get_rels ($$) {
  return rels_from_tbl $_[0], $_[1];
} # get_rels

sub get_rels_all ($) {
  my $char = shift;

  my $rels = {};
  for my $ds (@$DataSets) {
    for (@{rels_from_tbl $ds->{key}, $char}) {
      $rels->{$_->[0]} ||= [$_->[0], []];
      push @{$rels->{$_->[0]}->[1]}, @{$_->[1]};
    }
  }

  return [map { $rels->{$_} } sort { $a cmp $b } keys %$rels];
} # get_rels_all

sub parse_input_char ($) {
  my $input = shift;
  return undef unless defined $input;

  my $c;
  if ($input =~ /^[0-9]+$/) {
    $c = chr $input;
  } elsif ($input =~ /^0x[0-9A-Fa-f]+$/) {
    $c = chr hex $input;
  }
  if (defined $c) {
    if ($c eq ":") {
      $c = "::";
    } elsif ($c eq '.') {
      $c = ':.';
    }
  } elsif ($input =~ /^:/) {
    $c = decode_web_utf8 $input;
  } elsif (length $input and not $input =~ /^\./) {
    $c = decode_web_utf8 $input;
  } else {
    die decode_web_utf8 "Bad input |$input|";
  }

  return $c;
} # parse_input_char

sub format_char ($) {
  my $char = shift;
  return sprintf '%s (%s)',
      (join ' ', map {
        sprintf 'U+%04X', ord $_
      } split //, $char),
      $char;
} # format_char

sub print_cluster ($$$) {
  my ($level, $cluster, $ds_key) = @_;
  
  my $chars = get_chars $level, $cluster, $ds_key;
  my $has_char = {map { $_ => 1 } @$chars};
  my $out_rels = {};
  for my $char (sort { $a cmp $b } @$chars) {
    print format_char $char;
    print "\n";
    
    my $rels = get_rels $ds_key, $char;
    for my $rel (@$rels) {
      if (not $has_char->{$rel->[0]}) {
        push @{$out_rels->{$rel->[0]} ||= []}, [$char, $rel];
      }
      if (0) {
        printf "  %s\n", format_char $rel->[0];
        for (@{$rel->[1]}) {
          my $rel_def = $DataRoot->{$ds_key}->{rels}->[$_];
          printf "    %s\n", $rel_def->{key};
        }
      }
    }
  } # $chars
  for my $to_char (sort { $a cmp $b } keys %$out_rels) {
    print join ", ", map { format_char $_->[0] } @{$out_rels->{$to_char}};
    print "\t-> ";
    print format_char $to_char;
    print "\n";
    for (@{$out_rels->{$to_char}}) {
      my $ffc = format_char $_->[0];
      for (@{$_->[1]->[1]}) {
        my $rel_def = $DataRoot->{$_->[0]}->{rels}->[$_->[1]];
        print "  ", $ffc, "\t-> ($_->[0])", $rel_def->{key}, "\n";
      }
    }
  }
} # print_cluster

sub print_route ($$) {
  my ($char1, $char2) = @_;
  my $max_distance = 30;

  my $found = [];
  my $current = [ [[$char1, []]] ];
  my $current_seen = {$char1 => 1};
  if ($char1 eq $char2) {
    push @$found, @$current;
  } else {
  
  my $char = $char1;
  while (1) {
    printf STDERR "length = %d, %d routes\n", 0+@{$current->[0]}, 0+@$current;
    my $next = [];
    my $next_seen = {%$current_seen};
    for my $route (@$current) {
      my $char = $route->[-1]->[0];
      my $rels = get_rels_all $char;
      for (@$rels) {
        #if ($current_seen->{$_->[0]}) {
        if ($next_seen->{$_->[0]}) {
          #
        } elsif ($_->[0] eq $char2) {
          push @$found, [@$route, [$_->[0], $_->[1]]];
        } else {
          push @$next, [@$route, [$_->[0], $_->[1]]];
        }
        $next_seen->{$_->[0]} = 1;
      }
    }
    last unless @$next;
    last if @$found;
    last if @{$next->[0]} > $max_distance;
    $current = $next;
    $current_seen = $next_seen;
  }

}

  for my $route (@$found) {
    print "----\n";
    for (@$route) {
      for (@{$_->[1]}) {
        my $rel_def = $DataRoot->{$_->[0]}->{rels}->[$_->[1]];
        print "  ($_->[0]) ", $rel_def->{key}, "\n";
      }
      print format_char $_->[0];
      print "\n";
    }
  }

  unless (@$found) {
    print "None found\n";
  }
} # print_route

sub main (@) {
  my $level = 'EQUIV';
  my $char1 = parse_input_char shift // '';
  my $char2 = parse_input_char shift;
  if (defined $char2) {
    print_route $char1, $char2;
  } else {
    for my $ds (@$DataSets) {
      print "------ $ds->{key} ------\n";
      my $cluster = get_cluster $level, $char1;
      print_cluster $level, $cluster, $ds->{key};
    }
  }
} # main

main (@ARGV);
