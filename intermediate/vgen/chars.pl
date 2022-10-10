use strict;
use warnings;

## Character prefixes
##
##   - <https://wiki.suikawiki.org/i/4523#anchor-149>
##   - merged-char-index.pl
##   - tbl.pl
##   - split-jsonl.pl
##   - swdata site.js

sub u_chr ($) {
  if ($_[0] <= 0x1F or (0x7F <= $_[0] and $_[0] <= 0x9F)) {
    return sprintf ':u%x', $_[0];
  }
  my $c = chr $_[0];
  if ($c eq ":" or $c eq "." or
      $c =~ /\p{Non_Character_Code_Point}|\p{Surrogate}/) {
    return sprintf ':u%x', $_[0];
  } else {
    return $c;
  }
} # u_chr

sub u_hexs ($) {
  my $s = shift;
  my $i = 0;
  return join '', map {
    my $t = u_chr hex $_;
    if ($i++ != 0) {
      $t = '.' if $t eq ':u2e';
      $t = ':' if $t eq ':u3a';
    }
    if (1 < length $t) {
      return join '', map {
        sprintf ':u%x', hex $_;
      } split /\s+/, $s;
    }
    $t;
  } split /\s+/, $s
} # u_hexs

sub is_private ($) {
  my $char = shift;

  if (1 == length $char) {
    my $cc = ord $char;
    if (0xE000 <= $cc and $cc <= 0xF8FF) {
      return 1;
    } elsif (0xF0000 <= $cc and $cc <= 0xFFFFD) {
      return 1;
    } elsif (0x100000 <= $cc and $cc <= 0x10FFFD) {
      return 1;
    }
  }

  return 0;
} # is_private

sub is_han ($) {
  my $char = shift;
  if (1 == length $char) {
    my $c = ord $char;
    if (0x2E80 <= $c and $c <= 0x2FDF) {
      return 1;
    } elsif (0x3192 <= $c and $c <= 0x319F) {
      return 1;
    } elsif (0x31C0 <= $c and $c <= 0x31EF) {
      return 1;
    } elsif (0x4DC0 <= $c and $c <= 0x4DFF) {
      return 0;
    } elsif (0x3400 <= $c and $c <= 0x9FFF) {
      return 1;
    } elsif (0xF900 <= $c and $c <= 0xFAFF) {
      return 1;
    } elsif (0x20000 <= $c and $c <= 0x3FFFF) {
      return 1;
    } elsif ({
      0x3005 => 1, 0x3007 => 1, 0x3038 => 1, 0x3039 => 1, 0x393A => 1,
    }->{$c}) {
      return 1;
    } elsif ($c == 0x30B1 or $c == 0x30F6) { # ke
      return -1;
    }
  } elsif ($char =~ /^:aj([0-9]+)$/) {
    my $n = $1;
    if ($n == 658) { # shime
      return -1;
    } elsif ((656 <= $n and $n <= 659) or
        (1125 <= $n and $n <= 7477) or
        (7633 <= $n and $n <= 7886) or
        (7961 <= $n and $n <= 8004) or
        (8266 <= $n and $n <= 8267) or
        (8284 <= $n and $n <= 8285) or
        (8359 <= $n and $n <= 8717) or
        (13320 <= $n and $n <= 15443) or
        (16779 <= $n and $n <= 20316) or
        (21071 <= $n and $n <= 23057) or

        (7621 <= $n and $n <= 7623) or
        $n == 8054 or
        (8321 <= $n and $n <= 8326)) {
      return 1;
    }
  } elsif ($char =~ /^:aj2-([0-9]+)$/) {
    my $n = $1;
    if ((267 <= $n and $n <= 6067)) {
      return 1;
    }
  } elsif ($char =~ /^:ac([0-9]+)$/) {
    my $n = $1;
    if ((281 <= $n and $n <= 289) or
        (353 <= $n and $n <= 364) or
        (536 <= $n and $n <= 561) or
        (595 <= $n and $n <= 13645) or
        (13754 <= $n and $n <= 13756) or
        (14056 <= $n and $n <= 14062) or
        (14123 <= $n and $n <= 17407) or
        (17608 <= $n and $n <= 18784) or
        (18844 <= $n and $n <= 19168)) {
      return 1;
    }
  } elsif ($char =~ /^:ag([0-9]+)$/) {
    my $n = $1;
    if ($n == 104 or
        (940 <= $n and $n <= 7703) or
        (7717 <= $n and $n <= 9896) or
        (9992 <= $n and $n <= 10000) or
        (10024 <= $n and $n <= 10024) or
        (10072 <= $n and $n <= 22126) or
        (22398 <= $n and $n <= 22400) or
        (22428 <= $n and $n <= 29058)) {
      return 1;
    }
  } elsif ($char =~ /^:u-(?:immi|juki)-[0-9a-f]+$/) {
    return 1;
  }
  return 0;
} # is_han

#is_kana
#ac 13749 - 13752 13757 13761 - 13929 17606 17607
#ag 356 - 524
# 10019 - 10026 22359 - 22397
#aj1 332 - 389 391 - 421 516 - 598 658 660 842 - 1010
# 7585 - 7600 7918 - 7955 7958 - 7960 8038 - 8052 8183 8264 8265
# 8313 - 8316 8327 - 8348 [+ 8720, ...]
#
#is_alpha
#ac 5 - 7 17 - 26 33 - 59 66 - 91 96 - 97 175 178 194 206 235 - 238
#   259 260 262 - 279 333 - 352 365 - 465 526 - 535 562 - 594
#   13652 - 13654 13664 - 13674 13680 - 13706 - 13713 - 13738
#   13930 - 13995 14009 - 14048 14054 14055 17412 - 17414 17424 - 17433
#   17440 - 17466 17473 - 17498 17503 17504 17510 - 17512 17522 - 17531
#   17538 - 17569 17571 - 17596 17601 - 17605 18785 - 18843
#ag 5 - 7 17 - 26 33 - 59 66 - 91 133 134 145 146 165 - 172 180 - 209
#   250 - 261 265 - 267 277 - 286 293 - 319 326 - 351
#   525 - 572 602 - 699 817 - 819 829 - 838 845 - 871 878 - 903 908 - 939
#   9897 - 9906 9914 - 9915
#   10002 - 10012 10016 10048 10056 - 10058
#   22131 - 22133 22143 - 22152 22159 - 22185 22192 - 22217
#   22222 - 22224 22229 - 22231 22241 - 22250 22257 - 22283
#   22290 - 22315 22320 - 22351 22353 - 22356 22358 29059 - 29062
#aj2- 15 - 266
#aj1 5 - 7 17 - 26 33 - 59 66 - 91 102 103 105 - 107 112 113 125 139 - 150
#    152 154 157 - 185 187 - 214 216 - 225 227 - 230 235 - 237 247 - 256
#   263 - 289 296 - 321 599 - 611 614 - 628 630 632 651 - 654 
#  710 - 715 717 719 - 720 754 755 759 760 769 - 772 780 - 841
# 1011 - 1124 7775 - 7584 7601 - 7607 7610 - 7612 7624 7625
# 8020 - 8037 8053 8055 8059 - 8070 8092 - 8101 8182 8184 - 8190 8192 - 8195
# 8225 8226 8285 - 8308 [+ 8720, ...]


sub insert_rel ($$$$$) {
  my ($data, $c1, $c2, $reltype, $cmode) = @_;
  my $key = 'variants';

  # $cmode auto kana private
  if ($cmode eq 'auto') {
    if (is_han $c1 and is_han $c2) {
      $key = 'hans';
    }
  } elsif ($cmode eq 'private') {
    if (is_han $c1 or is_han $c2) {
      $key = 'hans';
    }
  }

  $data->{$key}->{$c1}->{$c2}->{$reltype} = 1;
} # insert_rel

sub classify_rels ($) {
  my $data = shift;

  my $c1s = [keys %{$data->{variants}}];
  for my $c1 (@$c1s) {
    my $c2s = [keys %{$data->{variants}->{$c1}}];
    for my $c2 (@$c2s) {
      if (is_han $c1 and is_han $c2) {
        $data->{hans}->{$c1}->{$c2} = 1;
        delete $data->{variants}->{$c1}->{$c2};
      }
    }
    unless (keys %{$data->{variants}->{$c1}}) {
      delete $data->{variants}->{$c1};
    }
  }
} # classify_rels

1;

## License: Public Domain.
