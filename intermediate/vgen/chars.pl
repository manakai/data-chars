use strict;
use warnings;
use JSON::PS;

## Character prefixes
##
##   - <https://wiki.suikawiki.org/i/4523#anchor-149>
##   - merged-char-index.pl
##   - split-jsonl.pl
##   - tbl.pl
##   - swdata site.js

my $IDC = q/\x{2FF0}-\x{2FFF}\x{31EF}/;

sub u_chr ($) {
  if ($_[0] <= 0x1F or (0x7F <= $_[0] and $_[0] <= 0x9F) or
      $_[0] > 0x10FFFF) {
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

sub wrap_string ($) {
  my $s = shift;
  if ($s =~ /^[:.]/ or
      $s =~ /[\x00-\x1F\x7F-\x9F\p{Non_Character_Code_Point}\p{Surrogate}]/) {
    return join '', map { sprintf ':u%x', ord $_ } split //, $s;
  } else {
    return $s;
  }
} # wrap_string

sub normalize_char ($) {
  my $c = shift;
  if ($c =~ /^:u([0-9a-f]+)$/) {
    return u_chr hex $1;
  } else {
    return $c;
  }
} # normalize_char

sub is_not_ivs_char ($) {
  return $_[0] !~ /^[\x{E0100}-\x{E01EF}]$/;
}

sub is_heisei_char ($) {
  return $_[0] =~ /^:(?:J[A-FT]|FT|HG|I[ABP]|JMK|KS|TK|AR)[0-9A-F]+S*$/;
} # is_heisei_char

sub split_for_string_contains ($) {
  my $s = shift;
  if ($s =~ /^:/) {
    return grep { is_not_ivs_char $_ } map { normalize_char $_ } grep { length } split /(?=:)/, $s;
  } else {
    return map { wrap_string $_ } grep { is_not_ivs_char $_ } split //, $s;
  }
} # split_char

# PUA
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

sub is_han ($);
sub is_han ($) {
  my $char = shift;
  if (1 == length $char) {
    my $c = ord $char;
    if (0x2E80 <= $c and $c <= 0x2FDF) {
      return 1;
    } elsif (0x3021 <= $c and $c <= 0x3029) { # numeral
      return 1;
    } elsif (0x3192 <= $c and $c <= 0x319F) { # kanbun
      return 1;
    } elsif (0x31C0 <= $c and $c <= 0x31EF) {
      return 1;
    } elsif (0x4DC0 <= $c and $c <= 0x4DFF) {
      return 0;
    } elsif ({
      0x4E44, 1, 0x2CF00, 1, 0x2A708, 1,0x2CEFF, 1, 0x2CF02, 1,
    }->{$c}) {
      return 0;
    } elsif (0x3400 <= $c and $c <= 0x9FFF) {
      return 1;
    } elsif (0xF900 <= $c and $c <= 0xFAFF) {
      return 1;
    } elsif (0x1D372 <= $c and $c <= 0x1D376) {
      return 1;
    } elsif (0x20000 <= $c and $c <= 0x3FFFF) {
      return 1;
    } elsif ({
      0x3005 => 1, 0x3007 => 1, 0x3038 => 1, 0x3039 => 1, 0x303A => 1,
      0x16FF0 => 1, 0x16FF1 => 1,
    }->{$c}) {
      return 1;
    } elsif ($c == 0x30B1 or $c == 0x30F6 or # ke
             $c == 0x303B or # ditto
             $c == 0x3068 or # to
             $c == 0x30BF or # ta
             $c == 0x30F1) { # we
      return -1;
    }
  } elsif (2 == length $char) {
    if (is_han substr $char, 0, 1) {
      if ((substr $char, 1) =~ /\A\p{Variation_Selector}\z/) {
        return 1;
      }
    }
  } elsif ($char =~ /^:cjkvi:/) {
    return 1;
  } elsif ($char =~ /^:u-(?:immi|juki)-[0-9a-f]+$/) {
    return 1;
  } elsif ($char =~ /^:u-arib-(e7[6-9a-f][0-9a-f]|e8[0-9a-f]{2})$/) {
    return 1;
  } elsif ($char =~ /^:jis1-(1[4-9]|[2-9][0-9])-([0-9]+)$/) {
    return 1;
  } elsif ($char =~ /^:jis2-(1[6-9]|[2-9][0-9])-([0-9]+)$/) { # XXX
    return 1;
  } elsif ($char =~ /^:jis-arib-1-92-([789]|10|2[6789]|3[01])$/) {
    return 1;
  } elsif ($char =~ /^:MJ([0-9]+)$/) {
    my $n = 0+$1;
    if ($n == 2 or $n == 6376 or $n == 6377 or
        $n == 3 or
        $n == 56854 or
        $n == 56850 or $n == 56853) {
      return 0;
    } else {
      return 1;
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
  } elsif (is_heisei_char $char) {
    return 1;
  } elsif ($char =~ /^:(?:gt|mh)[0-9]+$/) {
    return 1;
  } elsif ($char =~ /^:tron[238]-/) {
    return 1;
  } elsif ($char =~ /^:tron9-[2-7].[2-7]./) {
    return 1;
  } elsif ($char =~ /^:m([0-9]+)'*$/ and
           $1 < 50000) {
    return 1;
  } elsif ($char =~ /^:[$IDC]/o) {
    return 1;
  }
  
  return 0;
} # is_han

=pod

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

=cut

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

sub is_kana ($);
sub is_kana ($) {
  my $c = shift;

  if (1 == length $c) {
    my $cc = ord $c;

    ## Kana
    if (0x3031 <= $cc and $cc <= 0x3035) {
      return 1;
    } elsif (0x3041 <= $cc and $cc <= 0x3096) {
      return 1;
    } elsif (0x3099 <= $cc and $cc <= 0x309F) {
      return 1;
    } elsif (0x30A1 <= $cc and $cc <= 0x30FA) {
      return 1;
    } elsif (0x30FC <= $cc and $cc <= 0x30FF) {
      return 1;
    } elsif (0x31F0 <= $cc and $cc <= 0x31FF) {
      return 1;
    } elsif (0xFF66 <= $cc and $cc <= 0xFF9F) {
      return 1;
    } elsif (0x1B000 <= $cc and $cc <= 0x1B122) {
      return 1;
    } elsif (0x1B150 <= $cc and $cc <= 0x1B152) {
      return 1;
    } elsif (0x1B164 <= $cc and $cc <= 0x1B167) {
      return 1;
    } elsif ({
      0x27B0 => 1, # ~
      0x3030 => 1, # ~
      
      0x303C => 1, # re
      0x3191 => 1, # masu
      0x3006 => 1, 0x4E44 => 1, # shime
      0x2CF00 => 1, # tame
      0x2A708 => 1, # tomo
      0x2CEFF => 1, 0x2CF02 => 1, # nari

      0x3099 => 1,
      0x309A => 1,
      0x309B => 1,
      0x309C => 1,
      0x3031 => 1,
      0x3032 => 1,
      0x3033 => 1,
      0x3034 => 1,
      0x3035 => 1,
      0x303B => 1,
    }->{$cc}) {
      return 1;
    } elsif ({
      0x301C => 1,
      0xFF5E => 1,
    }->{$cc}) {
      return -1;

    ## Bopomofo
    } elsif (0x3100 <= $cc and $cc <= 0x312F) {
      return 1;
    } elsif (0x31A0 <= $cc and $cc <= 0x31BF) {
      return 1;
    } elsif ({
      0x02EA => 1, 0x02EB => 1,
    }->{$cc}) {
      return 1;
    } elsif ({
      #0x02C9 => 1,
      0x02CA => 1, 0x02C7 => 1, 0x02CB => 1, 0x02D9 => 1,
    }->{$cc}) {
      return -1;
    }
  }

  ## Kana
  if ($c =~ /^:MJ([0-9]+)$/) {
    my $cc = 0+$1;
    if ({
      2 => 1, 6376 => 1, 6377 => 1, # shime
      3 => 1, # ditto
      56854 => 1, # tame
      56850 => 1, 56853 => 1, # nari
    }->{$cc}) {
      return 1;
    }
  } elsif ($c =~ /^:koseki-9[0-9]{5}$/) {
    return 1;
  } elsif ($c =~ /^:tron9-[8][0-9a-f]{3}$/) {
    return 1;
  } elsif ($c eq ':wmc:Kunten_-n.gif') {
    return 1;
  }

  ## Kamiyo
  if ($c =~ /^:tron9-[9][45][0-9a-f]{2}$/) {
    return 1;
  }

  ## Bopomofo
  if ($c =~ /^:cns1-5-(?:7[6789]|80)$/) {
    return 1;
  } elsif ($c =~ /^:cccii1-15-(?:4[89]|5[01])$/) {
    return 1;
  }

  ## Gugyeol
  if ($c =~ /^:u-hanyang-([0-9a-f]+)$/) {
    my $cc = hex $1;
    if (0xF67E <= $cc and $cc <= 0xF77C) {
      return 1;
    }
  }

  ## Kana
  if ($c =~ /^:u([0-9a-f]+):u-mac-f87e$/) {
    if (is_kana chr hex $1) {
      return 1;
    }
  }

  if ($c =~ /^:aj([0-9]+)$/) {
    return 1 if {
      16326 => 1,
      16327 => 1,
    }->{$1};
  } elsif ($c =~ /^:aj-ext-([0-9]+)$/) {
    return 1 if 23110 <= $1 and $1 <= 23121;
    return 1 if 23172 <= $1 and $1 <= 23185;
    return 1 if 23291 <= $1 and $1 <= 23314;
  }

  return 1 if $c =~ /^:u-jitaichou-/;
  return 1 if {
    ':jisfusai12' => 1,
    ':jisfusai13' => 1,
    ':jisfusai14' => 1,
    ':jisfusai15' => 1,
    ':jisfusai16' => 1,
    ':jisfusai17' => 1,
    ':jisfusai18' => 1,
    ':jisfusai1678' => 1,
    ':UTC-03396' => 1,
  }->{$c};

  if ($c =~ /^[^:]./) {
    X: {
      for (split //, $c) {
        if (is_kana $_) {
          #
        } else {
          last X;
        }
      }
      return 1;
    }
  }
  
  return 0;
} # is_kana

sub is_kchar ($);
sub is_kchar ($) {
  my $c = shift;

  if (1 == length $c) {
    my $cc = ord $c;
    if (0x1100 <= $cc and $cc <= 0x11FF) {
      return 1;
    } elsif (0x3130 <= $cc and $cc <= 0x318F) { # fullwidth
      return 1;
    } elsif (0xA960 <= $cc and $cc <= 0xA97F) {
      return 1;
    } elsif (0xAC00 <= $cc and $cc <= 0xD7AF) { # syllable
      return 1;
    } elsif (0xD7B0 <= $cc and $cc <= 0xD7FF) {
      return 1;
    } elsif (0xFFA0 <= $cc and $cc <= 0xFFDF) { # halfwidth
      return 1;
    } elsif ($cc == 0x302E or $cc == 0x302F) { # combining
      return 1;
    }
  } elsif ($c =~ /^[^:]/) {
    X: {
      for (split //, $c) {
        if (is_kchar $_) {
          #
        } else {
          last X;
        }
      }
      return 1;
    }
  }

  if ($c =~ /^:u-old-([0-9a-f]+)$/) {
    my $cc = hex $1;
    if (0x3400 <= $cc and $cc <= 0x4DFF) {
      return 1;
    }
  }

  if ($c =~ /^:u-hanyang-([0-9a-f]+)$/) {
    my $cc = hex $1;
    if (0xE0BC <= $cc and $cc <= 0xEFFF) { # syllable
      return 1;
    } elsif (0xF100 <= $cc and $cc <= 0xF66E) {
      return 1;
    } elsif (0xF784 <= $cc and $cc <= 0xF8F7) {
      return 1;
    }
  }

  if ($c =~ /^:u-jeju-([0-9a-f]+)$/) {
    my $cc = hex $1;
    if (0xE001 <= $cc and $cc <= 0xE0A0) { # syllable
      return 1;
    }
  }

  if ($c =~ /^:u-kps-([0-9a-f]+)$/) {
    my $cc = hex $1;
    if (0xF113 <= $cc and $cc <= 0xF118) {
      return 1;
    } elsif (0xF120 <= $cc and $cc <= 0xF122) {
      return 1;
    }
  }

  return 0;
} # is_kchar

sub sjis_char ($$$) {
  my ($prefix, $b1, $b2) = @_;

  my $ten = $b2 < 0x7F ? $b2 - 0x40 + 1 : $b2 - 0x41 + 1;
  my $ku = $b1 < 0xE0 ? $b1 - 0x81 : (0x9F - 0x81 + 1) + $b1 - 0xE0;
  $ku *= 2;
  $ku++;
  if ($ten > 94) {
    $ten -= 94;
    $ku++;
  }

  if ($prefix eq ':jis-dos-1-') {
    if ($ku < 85) {
      $prefix = ':jis1-';
    }
  }

  if ($prefix eq ':jis-mac-1-') {
    if ($ku < 85 and not (9 <= $ku and $ku <= 15)) {
      $prefix = ':jis1-';
    }
  }

  return sprintf '%s%d-%d', $prefix, $ku, $ten;
} # sjis_char

sub is_b5_variant ($) {
  my $c = shift;
  return 1 if 0x8140 <= $c and $c <= 0xA0FE; # U+EEB8 ... U+F6B0 (0x8DFE) U+E311 (0x8E40) ... U+EEB7
  # U+F6B1 (0xC6A1) ... U+F81D
  return 1 if 0xC8D4 <= $c and $c <= 0xC8FE; # U+F81E ... U+F848
  return 1 if 0xFA40 <= $c and $c <= 0xFEFE; # U+E000 ... U+E310
  return 0;
} # is_b5_variant

sub is_ids ($) {
  return $_[0] =~ /^[$IDC]/o;
} # is_ids

sub is_ids_char ($) {
  return $_[0] =~ /^:[$IDC]|^:idch:/o;
} # is_ids_char

sub to_ids_char ($) {
  ## Assert: $_[0] is a |:|-prefixed IDS or a real IDS
  if ($_[0] =~ /^:/) {
    return ':idch' . $_[0];
  } else {
    return ':' . $_[0];
  }
} # to_ids_char

sub wrap_ids ($$) {
  my ($s, $prefix) = @_;
  return undef unless defined $s;
  use utf8;
  if ($prefix eq ':cjkvi:' and $s =~ /^([\x{E000}-\x{F8FF}])$/) {
    return sprintf ':u-cdp-%x', ord $1;
  }
  if ($s =~ /\A[？?〓\x{FFFD}]\z/) {
    return undef;
  } elsif ($s =~ /[\x21-\x7E？〓\x{FFFD}\x{303E}\x{E000}-\x{F7FF}\x{2FFB}\x{2194}\x{21B7}\x{2296}①-⑳（－]|CDP|&/) {
    return $prefix . $s;
  } elsif ($s =~ /^[$IDC]/o) {
    return $s;
  } elsif ((is_han $s or is_kana $s) and not $s =~ /^:/) {
    return $s;
  } else {
    return undef;
  }
} # wrap_ids

sub split_ids ($) {
  my $s = shift;
  if ($s =~ /^:/) {
    use utf8;
    if ($s =~ /^:cjkvi:(.+)$/) {
      my $t = $1;
      my @c;

      $t =~ s{([\x{E000}-\x{F7FF}])}{
        my $c = sprintf ':u-cdp-%x', ord $1;
        push @c, $c;
        '';
      }ge;
      
      $t =~ s{&CDP-([0-9A-F]+);}{
        my $c = sprintf ':b5-cdp-%x', hex $1;
        push @c, $c;
        '';
      }ge;
      
      $t =~ s{(（\w+）)}{
        my $c = ':cjkvi:' . $1;
        push @c, $c;
        '';
      }ge;
      
      $t =~ s{^(\w－\w)$}{
        my $c = ':cjkvi:' . $1;
        push @c, $c;
        '';
      }ge;
      
      die $s if $t =~ /[\x21-\x7E]/;

      push @c, grep { not /^[$IDC\x{303E}？〓\x{FFFD}①-⑳]$/o } split //, $t;
      
      return @c;
    } elsif ($s =~ /^:(yaids|radically):(.+)$/) {
      my $key = $1;
      my $t = $2;
      my @c;

      $t =~ s{(#\((?>[^()#]|#\([A-Za-z]+\))+\))}{
        my $c = ':'.$key.':' . $1;
        push @c, $c;
        '';
      }ge;
      $t =~ s{(\{[^()]+\})}{
        my $c = ':'.$key.':' . $1;
        push @c, $c;
        '';
      }ge;

      $t =~ s{[⿻⿴⿷⿶⿹]\[[^\[\]]+\]}{}g;

      if ($key eq 'yaids') {
        $t =~ s{([\p{Han}\p{Hiragana}\p{Katakana}\x{9000}-\x{9FFF}\x{30000}-\x{3FFFF}])([A-Za-z0-9.]+)}{
          my $c = ':' . $key . ':' . $1 . $2;
          push @c, $c;
          '';
        }ge;
      }

      # [:-1] [1]
      $t =~ s{\[[0-9]+\]}{}g;
      $t =~ s{\[:-[0-9]+\]}{}g;

      die $t if $t =~ /[\x21-\x7E]/;
      push @c, grep { not /^[$IDC\x{303E}\x{2194}\x{21B7}〓]$/o } split //, $t;
      
      return @c;
    } elsif ($s =~ /:hkcs-(.+)$/) {
      my $t = $1;
      my @c;

      $t =~ s{\{(?:hkc[ds]-([0-9A-Za-z-]+)|(5202-v01))\}}{
        my $c = ':hkcs-' . ($1 // $2);
        push @c, $c;
        '';
      }ge;
      
      push @c, grep { not /^[$IDC\x{303E}?？〓]$/o } split //, $t;

      die $t if $t =~ /[\x21-\x7E]/;

      return @c;
    } elsif ($s =~ /:utc:(.+)$/) {
      my $t = $1;
      my @c;

      $t =~ s{\[([0-9A-Z-]+)\]}{
        my $c = sprintf ':irg-' . $1;
        push @c, $c;
        '';
      }ge;

      $t =~ s{[$IDC\x{303E}?？]}{}go;
      die $t if $t =~ /[\x21-\x7E]/;
      push @c, split //, $t;

      return @c;
    } elsif ($s =~ /:babel:(.+)$/) {
      my $t = $1;
      my @c;

      $t =~ s{(\{[0-9A-Z-]+\})}{
        my $c = sprintf ':babel:' . $1;
        push @c, $c;
        '';
      }ge;
      
      push @c, grep { not /^[$IDC\x{303E}?？\x{2194}\x{21B7}\x{2296}]$/o } split //, $t;

      die $t if $t =~ /[\x21-\x7E]/;

      return @c;
    } elsif ($s =~ /:gw-(.+)$/) {
      my $t = join '', map { s/^u//; chr hex $_ } split /-/, $1;
      my @c;

      push @c, grep { not /^[$IDC\x{303E}?？]$/o } split //, $t;

      return @c;
    } elsif ($s =~ /:mj:(.+)$/) {
      my $t = $1;
      my @c;

      push @c, grep { not /^[$IDC\x{303E}]$/o } split //, $t;

      die $t if $t =~ /[\x21-\x7E？]/;

      return @c;
    } elsif ($s =~ /^:(?:u-cdp-|gb[0-9]+)[0-9a-f-]+$/) {
      return ($s);
    } else {
      die $s;
    }
  } else {
    die $s if $s =~ /[\x{E000}-\x{F7FF}]/;
    return grep { not /^[$IDC]$/o } split //, $s;
  }
} # split_ids

sub glyph_to_char ($) {
  my $g = shift;
  if ($g =~ /^MJ/) {
    return ":" . $g;
  #} elsif ($g =~ /^aj([0-9]+)$/) {
  #  return sprintf ':aj%d', $1;
  } elsif ($g =~ /^shs([0-9]+)$/) {
    return sprintf ':aj-shs-%d', $1;
  } elsif ($g =~ /^g([0-9]+)$/) {
    return sprintf ':swg%d', $1;
  } elsif ($g =~ /^[a-z][0-9a-z_-]+$/) {
    return ':gw-' . $g;
  } elsif (is_heisei_char ':' . $g) {
    return ':' . $g;
  } else {
    die "Bad glyph |$g|";
  }
} # glyph_to_char

sub get_vkey ($) {
  my $c = shift;

  return 'hans' if is_han $c > 0;
  return 'kanas' if is_kana $c > 0;
  return 'kchars' if is_kchar $c > 0;

  return 'variants';
} # get_vkey

sub insert_rel ($$$$$) {
  my ($data, $c1, $c2, $reltype, $cmode) = @_;
  my $key = 'variants';

  # $cmode auto kana private
  if ($cmode eq 'auto' or $cmode eq 'autok') {
    if (is_han $c1 and is_han $c2) {
      $key = 'hans';
    } elsif (is_kana $c1 and is_kana $c2) {
      $key = 'kanas';
    } elsif (is_kchar $c1 and is_kchar $c2) {
      $key = 'kchars';
    } elsif ($cmode eq 'autok' and
             (is_kana (substr $c1, -1) or
              is_kana (substr $c2, -1))) {
      $key = 'kanas';
    }
  } elsif ($cmode eq 'kana') {
    $key = 'kanas';
  } elsif ($cmode eq 'private') {
    if (is_han $c1 or is_han $c2) {
      $key = 'hans';
    }
  } elsif ($cmode eq 'desc') {
    $key = 'descs';
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

sub _print_rel_data ($$) {
  my $data = shift;
  my $file = shift;

  for my $key (sort { $a cmp $b } keys %$data) {
    printf $file "*%s\x0A", $key;
    for my $c1 (sort { $a cmp $b } keys %{$data->{$key}}) {
      printf $file "-%s\x0A", perl2json_bytes $c1;
      for my $c2 (sort { $a cmp $b } keys %{$data->{$key}->{$c1}}) {
        printf $file "%s\x0A", perl2json_bytes $c2;
        for my $rel_type (sort { $a cmp $b } keys %{$data->{$key}->{$c1}->{$c2}}) {
          my $rt = perl2json_bytes $rel_type;
          $rt =~ s/"//g;
          printf $file "%s\x0A", $rt;
        }
      }
    }
  }
} # _print_rel_data

sub print_rel_data ($) { _print_rel_data $_[0] => \*STDOUT }
sub write_rel_data ($$) { _print_rel_data $_[0] => $_[1]->openw }

sub write_rel_data_sets ($$$$) {
  my ($in_data, $container_path, $name_key, $patterns) = @_;

  my $current_data = {};
  for my $key (keys %$in_data) {
    $current_data->{$key} = {%{$in_data->{$key}}};
  }

  my $i = 1;
  for my $pattern (@$patterns) {
    my $path = $container_path->child ("$name_key-$i.list");
    my $data = {};
    for my $key (keys %$current_data) {
      my @v = grep { /^$pattern/ } keys %{$current_data->{$key}};
      for (@v) {
        $data->{$key}->{$_} = delete $current_data->{$key}->{$_};
      }
    }
    write_rel_data $data => $path;
    $i++;
  }
  {
    my $path = $container_path->child ("$name_key-0.list");
    write_rel_data $current_data => $path;
  }
} # write_rel_data_sets

sub parse_rel_data_file ($$) {
  my ($file, $data) = @_;
  local $/ = "\x0A";
  my $key;
  my $c1;
  my $c2;
  while (<$file>) {
    if (/^-(".*")$/) {
      $c1 = json_bytes2perl $1;
    } elsif (/^(".*")$/) {
      $c2 = json_bytes2perl $1;
    } elsif (/^\*(.+)$/) {
      $key = $1;
    } elsif (/^([\x20-\x5B\x5D-\x7E]+)$/) {
      $data->{$key}->{$c1}->{$c2}->{$1} = 1;
    } elsif (/^(.+)$/) {
      my $rel_type = json_bytes2perl qq{"$1"};
      $data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    }
  }
} # parse_rel_data_file

1;

## License: Public Domain.
