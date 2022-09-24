use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;
use Web::Encoding;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $DataPath = $RootPath->child ('intermediate/variants');
my $TablePath = $RootPath->child ('local/vv-tables');

binmode STDOUT, qw(:encoding(utf-8));
binmode STDERR, qw(:encoding(utf-8));

my $Data;
{
  my $path = $DataPath->child ('cluster-root.json');
  $Data = json_bytes2perl $path->slurp;
}
my $TableMeta;
{
  my $path = $TablePath->child ('meta.json');
  $TableMeta = json_bytes2perl $path->slurp;
}
{
  my $path = $TablePath->child ('clusters.tbl');
  my $table = $path->slurp;
  sub cluster_index_from_tbl ($$) {
    my $def = $_[0];

    my $offset = $def->{offset} + $_[1] * 3;
    if ($def->{offset_next} <= $offset) {
      return undef;
    }
    
    my $x = "\x00" . substr $table, $offset, 3;
    return unpack ('L>', $x);
  } # cluster_index_from_tbl

  sub chars_from_tbl ($$) {
    my $level = shift;
    my $index = shift;
    my $x = substr ((pack 'L>', $index), 1);
    my $length = length $table;
    my $chars = [];
    my @def = @{$TableMeta->{tables}};
    my $i = 0;
    while ($i < $length) {
      if ($x eq substr $table, $i, 3) {
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
  my $path = $TablePath->child ('rels.tbl');
  my $table = $path->slurp;
  sub rels_from_tbl ($) {
    my $char = shift;
    return [] if $char =~ /\x00/;
    my $bchar = (encode_web_utf8 $char) . "\x01";
    my $lbchar = length $bchar;
    my $i = 0;
    my $l = length $table;
    while ($i < $l) {
      if ((substr $table, $i, $lbchar) eq $bchar) {
        $i += $lbchar;
        my $x = index $table, "\x00", $i;
        return [] if $x < 0; # broken
        my $r = substr $table, $i, $x - $i;
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
            push @$rr, $v;
            $i2 += 2;
          }
          push @$rels, [(decode_web_utf8 $bc2), $rr];
        } # $y
        return $rels;
      } else { # not $bchar
        my $x = index $table, "\x00", $i;
        last if $x < 0; # broken
        $i = $x + 1;
      }
    }
    return [];
  } # rels_from_tbl
}

sub get_cluster ($$) {
  my $level = shift;
  if (1 == length $_[0]) {
    my $def;
    my $cc = ord $_[0];
    for (@{$TableMeta->{tables}}) {
      if ($_->{level_key} eq $level and
          $_->{type} eq 'unicode' and
          $_->{unicode_offset} <= $cc and $cc < $_->{unicode_offset_next}) {
        $def = $_;
        last;
      }
    }

    if (defined $def) {
      my $index = cluster_index_from_tbl $def, $cc - $def->{unicode_offset};
      return $index ? {index => $index} : undef if defined $index;
    }
  }

  if (2 == length $_[0]) {
    my $cc1 = ord $_[0];
    my $cc2 = ord substr $_[0], 1;
    my $def;
    for (@{$TableMeta->{tables}}) {
      if ($_->{level_key} eq $level and
          $_->{type} eq 'unicode-suffix' and
          $_->{suffix} == $cc2 and
          $_->{unicode_offset} <= $cc1 and $cc1 < $_->{unicode_offset_next}) {
        $def = $_;
        last;
      }
    }

    if (defined $def) {
      my $index = cluster_index_from_tbl $def, $cc1 - $def->{unicode_offset};
      return $index ? {index => $index} : undef if defined $index;
    }
  }

  {
    my $index = $TableMeta->{others}->{$level}->{$_[0]};
    return undef unless $index;

    return {index => $index};
  }
} # get_cluster

sub get_chars ($$) {
  my ($level, $cluster) = @_;

  my $chars = [];
  my $index = $cluster->{index} // return $chars;

  for (keys %{$TableMeta->{others}->{$level}}) {
    if ($TableMeta->{others}->{$level}->{$_} == $index) {
      push @$chars, $_;
    }
  }

  push @$chars, @{chars_from_tbl $level, $index};

  return $chars;
} # get_chars

sub get_rels ($) {
  my $char = shift;

  return rels_from_tbl $char;
} # get_rels

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

sub print_cluster ($$) {
  my ($level, $char) = @_;
  
  my $cluster = (get_cluster $level, $char) // {};
  my $chars = get_chars $level, $cluster;
  my $has_char = {map { $_ => 1 } @$chars};
  my $out_rels = {};
  for my $char (sort { $a cmp $b } @$chars) {
    print format_char $char;
    print "\n";
    
    my $rels = get_rels $char;
    for my $rel (@$rels) {
      if (not $has_char->{$rel->[0]}) {
        push @{$out_rels->{$rel->[0]} ||= []}, [$char, $rel];
      }
      if (0) {
        printf "  %s\n", format_char $rel->[0];
        for (@{$rel->[1]}) {
          my $rel_def = $TableMeta->{rels}->[$_];
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
        my $rel_def = $TableMeta->{rels}->[$_];
        print "  ", $ffc, "\t-> ", $rel_def->{key}, "\n";
      }
    }
  }
} # print_cluster

sub print_route ($$) {
  my ($char1, $char2) = @_;

  my $max_distance = 30;

  my $char = $char1;
  my $found = [];
  my $current = [ [[$char1, []]] ];
  my $current_seen = {$char1 => 1};
  while (1) {
    printf STDERR "length = %d, %d routes\n", 0+@{$current->[0]}, 0+@$current;
    my $next = [];
    my $next_seen = {%$current_seen};
    for my $route (@$current) {
      my $char = $route->[-1]->[0];
      my $rels = get_rels $char;
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

  for my $route (@$found) {
    print "----\n";
    for (@$route) {
      for (@{$_->[1]}) {
        my $rel_def = $TableMeta->{rels}->[$_];
        print "  ", $rel_def->{key}, "\n";
      }
      print format_char $_->[0];
      print "\n";
    }
  }
} # print_route

sub main (@) {
  my $level = 'EQUIV';
  my $char1 = parse_input_char shift // '';
  my $char2 = parse_input_char shift;
  if (defined $char2) {
    print_route $char1, $char2;
  } else {
    print_cluster $level, $char1;
  }
} # main

main (@ARGV);
