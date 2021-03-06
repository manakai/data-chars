package Charinfo::Set;
use strict;
use warnings;
use Path::Class;
use Charinfo::Name;
use Encode;

sub set_merge ($$) {
  my ($s1, $s2) = @_;
  my $result = [];
  my @range = sort { $a->[0] <=> $b->[0] } @$s1, @$s2;
  while (1) {
    if (@range <= 1) {
      push @$result, @range;
      last;
    }
    my $start = $range[0]->[0];
    my $end = (shift @range)->[1];
    while (2) {
      last if $end + 1 < $range[0]->[0];
      $end = $range[0]->[1] if $end < $range[0]->[1];
      shift @range;
      last unless @range;
    }
    push @$result, [$start, $end];
  }
  return $result;
} # set_merge

sub set_minus ($$) {
  my ($s1, $s2) = @_;
  my $result = [[-1, -1, 0]];
  my @def = sort { $a->[0] <=> $b->[0] || $a->[2] <=> $b->[2] }
      (map { [@$_, 0] } @$s1), (map { [@$_, 1] } @$s2);
  my $minus_end = -1;
  while (@def) {
    my $range = shift @def;
    if ($range->[2]) { # minus
      if ($result->[-1]->[0] <= $range->[0] and
          $range->[0] <= $result->[-1]->[1]) {
        if ($range->[0] <= $result->[-1]->[0]) {
          $result->[-1]->[0] = $range->[1] + 1;
          pop @$result unless $result->[-1]->[0] <= $result->[-1]->[1];
        } else { # $result->[-1]->[0] < $range->[0]
          if ($range->[0] <= $result->[-1]->[1]) {
            if ($range->[1] < $result->[-1]->[1]) {
              my $new_range = [$range->[1] + 1, $result->[-1]->[1]];
              if ($new_range->[0] <= $new_range->[1]) {
                unshift @def, $new_range;
                @def = sort { $a->[0] <=> $b->[0] || $a->[2] <=> $b->[2] } @def;
              }
            }
            $result->[-1]->[1] = $range->[0] - 1;
            pop @$result unless $result->[-1]->[0] <= $result->[-1]->[1];
          }
        }
      }
      $minus_end = $range->[1];
    } else {
      if ($range->[0] <= $minus_end and $minus_end < $range->[1]) {
        push @$result, [$minus_end + 1, $range->[1]]
            if $minus_end + 1 < $range->[1];
      } elsif ($range->[1] <= $minus_end) {
        #
      } else { # $minus_end < $range->[0]
        push @$result, $range;
      }
    }
  } # @def
  shift @$result; # [-1, -1, 0]
  return [map { [$_->[0], $_->[1]] } @$result];
} # set_minus


sub col2expr ($) {
  my $s = shift;
  my @s;
  my @c;
  $s =~ s{^(#.+)}{
    push @c, $1; '';
  }gem;
  $s =~ s{^[\x20\x09]*([0-9A-F][0-9A-F])((?:[\x20\x09]+[0-9A-F][0-9A-F](?:-[0-9A-F][0-9A-F])?)+)}{
    my ($r, @c) = ($1, grep {length} split /\s+/, $2);
    for (@c) {
      if (/([0-9A-F][0-9A-F])-([0-9A-F][0-9A-F])/) {
        push @s, sprintf '\u{%s%s}-\u{%s%s}', $r,$1, $r,$2;
      } else {
        push @s, sprintf '\u{%s%s}', $r,$_;
      }
    }
  }gem;
  return '[' . join ('', @s) . ']';
} # col2expr

my $SetD = file (__FILE__)->dir->parent->parent->parent->subdir ('src', 'set');
our $Depth = 0;
sub get_set ($) {
  my $name = $_[0];
  local $Depth = $Depth + 1;
  die "\$$name definition too deep\n" if $Depth > 100;
  return undef if
      not $name =~ m{\A[0-9A-Za-z][0-9A-Za-z_.:-]*\z} or
      $name =~ m{[_.:-]\z} or
      $name =~ m{\.\.} or
      $name =~ m{::};
  $name =~ s{:}{/}g;
  my $f = $SetD->file ($name . '.expr');
  return undef unless -f $f;
  my $src = decode 'utf-8', scalar $f->slurp;
  if ($src =~ /^\#format:\s*col\s*$/m) {
    $src = col2expr $src;
  }
  $src =~ s{\x0A\[\[COL\x0D?\x0A(.+?)\x0ACOL\]\]\s*(?:\x0A|$)}{col2expr $1}ges;
  my $set = __PACKAGE__->evaluate_expression ($src);
  die "Bad set definition \$$_[1]\n" unless defined $set;
  return $set;
} # get_set

sub get_set_metadata ($$) {
  my $name = $_[1];
  $name =~ s/^\$//;
  return undef if
      not $name =~ m{\A[0-9A-Za-z][0-9A-Za-z_.:-]*\z} or
      $name =~ m{[_.:-]\z} or
      $name =~ m{\.\.} or
      $name =~ m{::};
  $name =~ s{:}{/}g;
  my $f = $SetD->file ($name . '.expr');
  return undef unless -f $f;
  my $prop = {};
  for (split /\x0D?\x0A/, decode 'utf-8', scalar $f->slurp) {
    if (/^\s*#(\w+):(.+)$/) {
      my $name = $1;
      my $value = $2;
      $value =~ s/^\s+//;
      $value =~ s/\s+$//;
      $prop->{$name} = $value;
    }
  }
  return $prop;
} # get_set_metadata

sub get_set_list ($) {
  my @list;
  $SetD->recurse (callback => sub {
    my $f = $_[0];
    if (-f $f and $f =~ /\.expr\z/) {
      my $name = $f->relative ($SetD)->stringify;
      $name =~ s{/}{:}g;
      $name =~ s/\.expr$//;
      push @list, '$' . $name;
    }
  });
  return \@list;
} # get_set_list

sub evaluate_expression ($$) {
  my $input = $_[1];
  my $current = [];

  $input = join "\x0A", grep { not /^\s*#/ } split /\x0D?\x0A/, $input;

  my $op = '|';
  if ($input =~ s/^\s*-//) {
    $current = [[0x0000, 0x10FFFF]];
    $op = '-';
  }
  while (length $input) {
    if ($input =~ s/^\s*\[([^\[\]]*)\]//) {
      my $chars = $1;
      my $set = [];
      push @$set, [ord '-', ord '-'] if $chars =~ s/\A-//;
      push @$set, [ord '-', ord '-'] if $chars =~ s/-\z//;
      die "Bad range\n" if $chars =~ /\A-/ or $chars =~ /-\z/;
      my $in_range;
      while (length $chars) {
        my $code;
        if ($chars =~ s/^\\u([0-9A-Fa-f]{4})//) {
          $code = hex $1;
        } elsif ($chars =~ s/^\\u\{([0-9A-Fa-f]+)\}//) {
          $code = hex $1;
        } elsif ($chars =~ s/^\\U([0-9A-Fa-f]{8})//) {
          $code = hex $1;
        } elsif ($chars =~ s/^\\N\{([^{}]+)\}//) {
          my $name = $1;
          $code = Charinfo::Name->char_name_to_code ($name);
          die "Character |$name| not found\n" unless defined $code;
        } elsif ($chars =~ s/^\\\\//) {
          $code = 0x5C;
        } elsif ($chars =~ s/^\\//) {
          die "Broken escape: |\\$chars|\n";
        } elsif ($chars =~ s/^-//) {
          die "Broken range\n" if $in_range;
          $in_range = 1;
          next;
        } elsif ($chars =~ s/^\^//) {
          die "Bad ^\n";
        } elsif ($chars =~ s/^\s+//) {
          next;
        } elsif ($chars =~ s/^(.)//s) {
          $code = ord $1;
        } else {
          die "Somewhat broken\n";
        }
        if ($in_range) {
          die "Broken range\n" if $set->[-1]->[0] > $code;
          $set->[-1]->[1] = $code;
          $in_range = 0;
        } else {
          push @$set, [$code, $code];
        }
      }
      if ($op eq '|') {
        $current = set_merge $set, $current;
      } elsif ($op eq '-') {
        $set = set_merge $set, [];
        $current = set_minus $current, $set;
      } else {
        die "Unknown operation |$op|\n";
      }
      undef $op;
    } elsif ($input =~ s/^\s*\$([0-9A-Za-z_.:-]+)//) {
      my $set = get_set $1 or die "Unknown set |\$$1|\n";
      if ($op eq '|') {
        $current = set_merge $set, $current;
      } elsif ($op eq '-') {
        $current = set_minus $current, $set;
      } else {
        die "Unknown operation |$op|\n";
      }
      undef $op;
    } elsif ($input =~ s/^\s*([|-])//) {
      die "Bad operator" if defined $op;
      $op = $1;
    } elsif ($input =~ s/^\s*$//) {
      #
    } else {
      die "Bad input -> |$input|\n";
    }
  }
  die "Set expected (Input |$_[1]|, op |$op|)\n" if defined $op;

  return $current;
} # evaluate_expression

sub regexp_range_char ($) {
  my $c = $_[0];
  if ($c == 0x002D or
      $c == 0x0023 or
      $c == 0x0024 or
      $c == 0x0026 or
      $c == 0x003B or
      $c == 0x0040 or
      (0x005B <= $c and $c <= 0x005E)) { # #$&-;@[\]^
    return sprintf '\\u%04X', $c;
  } elsif (0x0021 <= $c and $c <= 0x007E) {
    return chr $c;
  } elsif ($c <= 0xFFFF) {
    return sprintf '\\u%04X', $c;
  } else {
    return sprintf '\\u{%X}', $c;
  }
} # regexp_range_char

sub serialize_set ($$) {
  my @result;
  push @result, '[';
  for my $range (@{$_[1]}) {
    if ($range->[0] == $range->[1]) {
      push @result, regexp_range_char $range->[0];
    } else {
      push @result, regexp_range_char $range->[0];
      push @result, '-';
      push @result, regexp_range_char $range->[1];
    }
  }
  push @result, q{]};
  return join '', @result;
} # serialize_set

1;

=head1 LICENSE

Copyright 2013-2019 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
