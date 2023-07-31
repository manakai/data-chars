use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/icjkvi');

my $Data = {};

my $Types = {};

{
  my $path = $TempPath->child ('hd2ucs.txt');
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    my $c1;
    my $c3;
    my $type3 = 'manakai:implements';
    if (s/^((J[ABCDEF]|FT|IA|IB|HG)([0-9][0-9])([0-9][0-9])(SS?|))\*?//) {
      $c1 = ':' . $1;
      $Types->{"$2----$5"}++;

      if ($2 eq 'JA' or $2 eq 'JC' or $2 eq 'JE' or $2 eq 'JF') {
        $c3 = sprintf ':jis1-%d-%d', $3, $4;
      } elsif ($2 eq 'JB' or $2 eq 'JD') {
        $c3 = sprintf ':jis2-%d-%d', $3, $4;
      }
    } elsif (s/^((IP|JT)([0-9A-F][0-9A-F])([0-9A-F][0-9A-F])(SS?|))\*?//) {
      my $v1 = $1;
      $c1 = ':' . $v1;
      $Types->{"$2----$5"}++;
      
      my $u = (hex $3) * 0x100 + hex $4;
      if ($2 eq 'IP') {
        $c3 = chr $u;
      } elsif ($2 eq 'JT') {
        if ($u < 0xA000 or
            (/^\tU\+([0-9A-F]+)/ and $u == hex $1) or
            (/^\t[=~]([A-Z0-9S]+)/ and defined $Data->{hans}->{':'.$1} and $Data->{hans}->{':'.$1}->{chr $u})) {
          $c3 = chr $u;
          $type3 .= ':juki';
        } else {
          $c3 = sprintf ':u-juki-%x', $u;
        }
      }
    } elsif (s/^((AR|KS|TK|JMK)([0-9]+)()(SS?|))\*?//) {
      $c1 = ':' . $1;
      $Types->{"$2-$5"}++;

      if ($2 eq 'KS') {
        $c3 = sprintf ':koseki%s', $3;
      } elsif ($2 eq 'TK') {
        $c3 = sprintf ':touki%s', $3;
      } elsif ($2 eq 'JMK') {
        $c3 = sprintf ':m%d', $3;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
    my $vkey = 'hans';

    s/U\+2A746\[A5\]$/U+2A746[17]/g;
    if (/^\s+U\+([0-9A-F]+)(\[U\]|)(?:\s+U\+([0-9A-F]+)\[(1[789]|[23][0-9])\]|)$/) {
      my $c2 = chr hex $1;
      my $vtype = 'cjkvi:hd2ucs';
      $vtype .= ':U' if $2 eq '[U]';
      $vkey = get_vkey $c2;
      $Data->{$vkey}->{$c1}->{$c2}->{$vtype} = 1;

      if (defined $3) {
        my $c4 = chr (hex $3) . chr (0xE0100 + $4 - 17);
        $Data->{$vkey}->{$c1}->{$c4}->{'cjkvi:hd2ucs:ivs'} = 1;
      }
    } elsif (/^\s+U\+([0-9A-F]+)\[(1[789]|2[0-9])\]\s+U\+([0-9A-F]+)(\[U\]|)$/) {
      my $c2 = chr hex $3;
      my $vtype = 'cjkvi:hd2ucs';
      $vtype .= ':U' if $4 eq '[U]';
      $vkey = get_vkey $c2;
      $Data->{$vkey}->{$c1}->{$c2}->{$vtype} = 1;

      if (defined $1) {
        my $c4 = chr (hex $1) . chr (0xE0100 + $2 - 17);
        $Data->{$vkey}->{$c1}->{$c4}->{'cjkvi:hd2ucs:ivs'} = 1;
      }
    } elsif (/^\s+U\+([0-9A-F]+)\[(1[789]|[234][0-9])\]$/) {
      my $c4 = chr (hex $1) . chr (0xE0100 + $2 - 17);
      $vkey = get_vkey $c4;
      $Data->{$vkey}->{$c1}->{$c4}->{'cjkvi:hd2ucs:ivs'} = 1;
    } elsif (/^\s+U\+([0-9A-F]+)(\[U\]|)\s+U\+([0-9A-F]+)(\[U\]|)$/) {
      my $c2 = chr hex $1;
      my $c4 = chr hex $3;
      $vkey = get_vkey $c2;
      $Data->{$vkey}->{$c1}->{$c2}->{'cjkvi:hd2ucs'.($2 eq '[U]' ? ':U' : '')} = 1;
      $Data->{$vkey}->{$c1}->{$c4}->{'cjkvi:hd2ucs'.($4 eq '[U]' ? ':U' : '')} = 1;
    } elsif (/^\s+(=|~)((?:J[ABCDEF]|FT|IA|IB|IB|HG|AR|KS|TK)[0-9]+S?S?)\*?$/) {
      my $c2 = ':' . $2;
      my $vtype = 'cjkvi:hd2ucs:' . $1;
      $Data->{$vkey}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (/^\s+(=|~)((?:JT|IP)(?:[0-9A-F][0-9A-F])(?:[0-9A-F][0-9A-F])S?S?)\*?$/) {
      my $c2 = ':' . $2;
      my $vtype = 'cjkvi:hd2ucs:' . $1;
      $Data->{$vkey}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (/^\s+JK-([0-9]+)$/) {
      my $c2 = ':m' . $1;
      my $vtype = 'cjkvi:hd2ucs';
      $Data->{$vkey}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (/^\s+JK-([0-9]+)\s+U\+([0-9A-F]+)$/) {
      my $c2 = ':m' . $1;
      my $vtype = 'cjkvi:hd2ucs';
      $Data->{$vkey}->{$c1}->{$c2}->{$vtype} = 1;
      my $c4 = chr hex $2;
      $Data->{$vkey}->{$c1}->{$c4}->{$vtype} = 1;
    } elsif (/^\s+CDP-([0-9A-F]+)$/) {
      my $c2 = sprintf ':b5-cdp-%x', hex $1;
      my $vtype = 'cjkvi:hd2ucs';
      $Data->{$vkey}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
    $Data->{$vkey}->{$c1}->{$c3}->{$type3} = 1 if defined $c3;
  }
}

{
  my $path = $TempPath->child ('cjkvi-data/hducs2juki.txt');
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    if (/^(([A-Z]{2})([0-9A-F]{4,})S*)\t+U\+([0-9A-F]+)([#*]?)\t+([0-9A-F]{4})$/) {
      my $c1 = ':' . $1;
      my $code2 = hex $4;
      my $c2 = chr $code2;
      my $code3 = hex $6;
      my $c3 = sprintf ':u-juki-%x', $code3;
      if ($code3 < 0xA000 or $code2 == $code3) {
        $c3 = chr $code3;
      }
      my $vkey = get_vkey $c2;
      $Data->{$vkey}->{$c1}->{$c3}->{'cjkvi:hducs2juki'} = 1;
      if ($c2 eq $c3) {
        #
      } else {
        $Data->{$vkey}->{$c2}->{$c3}->{'cjkvi:hducs2juki'.(length $5 ? ':' . $5 : '')} = 1;
      }
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)\t+JK-([0-9A-F]+)([']?)\t+([0-9A-F]{4})$/) {
      my $c1 = ':' . $1;
      my $c2 = sprintf ':m%d%s', $2, $3;
      my $code3 = hex $4;
      my $c3 = sprintf ':u-juki-%x', $code3;
      if ($code3 < 0xA000) {
        die;
        $c3 = chr $code3;
      }
      my $vkey = 'hans';
      $Data->{$vkey}->{$c1}->{$c3}->{'cjkvi:hducs2juki'} = 1;
      $Data->{$vkey}->{$c2}->{$c3}->{'cjkvi:hducs2juki'} = 1;
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)\t\t+([0-9A-F]{4})$/) {
      my $c1 = ':' . $1;
      my $code3 = hex $2;
      my $c3 = sprintf ':u-juki-%x', $code3;
      if ($code3 < 0xA000) {
        die;
        $c3 = chr $code3;
      }
      my $vkey = 'hans';
      $Data->{$vkey}->{$c1}->{$c3}->{'cjkvi:hducs2juki'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('cjkvi-data/hducs2ivs.txt');
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)\s+U\+([0-9A-F]+)\s+\[U\+([0-9A-F]+) U\+([0-9A-F]+)\]$/) {
      my $c1 = ':' . $1;
      my $c2_0 = (chr hex $3);
      my $c2 = $c2_0 . (chr hex $4);
      my $vkey = get_vkey $c2_0;
      $Data->{$vkey}->{$c1}->{$c2}->{'cjkvi:hducs2ivs'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('cjkvi-data/hducs2koseki.txt');
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)\t+U\+([0-9A-F]+)([#*]?)\t+([0-9]+)$/) {
      my $c1 = ':' . $1;
      my $c2 = chr hex $2;
      my $code3 = $4;
      my $c3 = $code3 <= 999999 ? sprintf ':koseki%06d', $code3 : sprintf ':touki%08d', $code3;
      my $vkey = get_vkey $c2;
      $Data->{$vkey}->{$c1}->{$c3}->{'cjkvi:hducs2koseki'} = 1;
      $Data->{$vkey}->{$c2}->{$c3}->{'cjkvi:hducs2koseki'.(length $3 ? ':' . $3 : '')} = 1;
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)\t+\(([0-9A-F]+)\)()\t+([0-9]+)$/) {
      my $c1 = ':' . $1;
      my $c2 = chr hex $2;
      my $code3 = $4;
      my $c3 = $code3 <= 999999 ? sprintf ':koseki%06d', $code3 : sprintf ':touki%08d', $code3;
      my $vkey = get_vkey $c2;
      $Data->{$vkey}->{$c1}->{$c3}->{'cjkvi:hducs2koseki'} = 1;
      $Data->{$vkey}->{$c2}->{$c3}->{'cjkvi:hducs2koseki:()'} = 1;
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)\t+JK-([0-9A-F]+)([']?)\t+([0-9]+)$/) {
      my $c1 = ':' . $1;
      my $c2 = sprintf ':m%d%s', $2, $3;
      my $code3 = $4;
      my $c3 = $code3 <= 999999 ? sprintf ':koseki%06d', $code3 : sprintf ':touki%08d', $code3;
      my $vkey = 'hans';
      $Data->{$vkey}->{$c1}->{$c3}->{'cjkvi:hducs2koseki'} = 1;
      $Data->{$vkey}->{$c2}->{$c3}->{'cjkvi:hducs2koseki'} = 1;
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)\t(?:\(EXT-E\)|)\t+([0-9]+)$/) {
      my $c1 = ':' . $1;
      my $code3 = $2;
      my $c3 = $code3 <= 999999 ? sprintf ':koseki%06d', $code3 : sprintf ':touki%08d', $code3;
      my $vkey = 'hans';
      $Data->{$vkey}->{$c1}->{$c3}->{'cjkvi:hducs2koseki'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('cjkvi-data/hd2cid.txt');
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)(\*?)\t+CID\+([0-9]+)$/) {
      my $c1 = ':' . $1;
      my $c2 = sprintf ':aj%d', $3;
      $Data->{hans}->{$c1}->{$c2}->{'cjkvi:hd2cid'} = 1;
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)(\*?)\t+CID\+([0-9]+)\t# subtle$/) {
      my $c1 = ':' . $1;
      my $c2 = sprintf ':aj%d', $3;
      $Data->{hans}->{$c1}->{$c2}->{'cjkvi:hd2cid:subtle'} = 1;
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)(\*?)$/) {
      #
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)(\*?)\t[=~]/) {
      #
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)(\*?)\t\t# Connectivity \/ CID\+([0-9]+)$/) {
      my $c1 = ':' . $1;
      my $c2 = sprintf ':aj%d', $3;
      $Data->{hans}->{$c1}->{$c2}->{'cjkvi:hd2cid:related'} = 1;
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)(\*?)\t\t# "." hook shape \(CID\+([0-9]+)\)$/) {
      my $c1 = ':' . $1;
      my $c2 = sprintf ':aj%d', $3;
      $Data->{hans}->{$c1}->{$c2}->{'cjkvi:hd2cid:related'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  use utf8;
  my $path = $TempPath->child ('cjkvi-ids/hanyo-ids.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^([A-Z]{2}[0-9A-F]{4,}S*)\*?\t+([\x{2E00}-\x{FFFF}\w\/]+)\s*$/) {
      my $c1 = ':' . $1;
      my $ids = $2;
      my $c2 = undef;
      if ($ids eq '？' or $ids eq '〓') {
        next;
      }
      $c2 = wrap_ids $ids, ':cjkvi:';
      unless (defined $c2) {
        $ids =~ s{(.)}{sprintf q{{%04X}}, ord $1}ges;
        die "Bad IDS |$ids|";
      }
      $Data->{idses}->{$c1}->{$c2}->{'cjkvi:ids'} = 1;
    } elsif (/^([A-Z]{2}[0-9A-F]{4,}S*)(\*?)\t+$/) {
      #
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

#use JSON::PS;
#warn perl2json_bytes_for_record $Types;

{
  my $path = $ThisPath->child ('hd-ids.list');
  write_rel_data {idses => delete $Data->{idses}} => $path;
}
write_rel_data_sets
    $Data => $ThisPath, 'hd',
    [
      qr/^:J[AC]/,
      qr/^:J[BD]/,
      qr/^:J/,
      qr/^:KS0/,
      qr/^:KS1/,
      qr/^:KS2/,
      qr/^:KS3/,
      qr/^:K/,
      qr/^:[A-Z]/,
      qr/^[\x{3000}-\x{6FFF}]/,
      qr/^[\x{7000}-\x{FFFF}]/,
    ];

## License: Public Domain.
