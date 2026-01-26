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

for (
  ['ids.txt'],
  ['ids-cdp.txt'],
  ['ids-ext-cdef.txt'],
  ['ws2015-ids.txt'],
  ['ws2015-ids-cdp.txt'],
) {
  use utf8;
  my $path = $TempPath->child ('cjkvi-ids/' . $_->[0]);
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    s/"$//;
    if (/^#/) {
      #
    } elsif (/^;/) {
      #
    } elsif (/^(?:U\+([0-9A-F]+)\s+\S|(\S+)|(CDP-[0-9A-F]+)\t&CDP-[0-9A-F]+;)((?:\s+\S+)+)\s*$/) {
      my @l = grep { length } split m{[\t/]}, $4;
      my @c1;
      if (defined $1) {
        push @c1, u_chr hex $1;
      } else {
        for (split m{/}, $2 // $3) {
          if (/^(?:KC|UTC).+$/) {
            push @c1, ':' . $_;
          } elsif (/^USAT([0-9]+)$/) {
            push @c1, sprintf ':sat%d', $1;
          } elsif (/^G_Z([0-9]+)$/) {
            push @c1, ':GZ-' . $1;
          } elsif (/^GHZR([0-9.]+)$/) {
            push @c1, ':GHZR-' . $1;
          } elsif (/^G_PGLG([0-9]+)$/) {
            push @c1, ':GPGLG-' . $1;
          } elsif (/^T([0-9A-F])-([0-9A-F]{2})([0-9A-F]{2})$/) {
            push @c1, sprintf ':cns%d-%d-%d',
                (hex $1), (hex $2) - 0x20, (hex $3) - 0x20;
          } elsif (/^T(13)-([0-9A-F]{2})([0-9A-F]{2})$/) {
            push @c1, sprintf ':cns%d-%d-%d',
                (hex $1), (hex $2) - 0x20, (hex $3) - 0x20;
          } elsif (/^CDP-([0-9A-F]+)$/) {
            push @c1, sprintf ':b5-cdp-%x', hex $1;
          } else {
            die $_;
          }
        }
      }
      for my $c1 (@c1) {
        for (@l) {
          my $ids = $_;
          next if $c1 eq $ids;
          my $sources = '';
          $sources = $1 if $ids =~ s/\[([A-Z]+)\]$//;
          my @source = split //, $sources;
          my @rel_type = 'cjkvi:ids';
          if (@source) {
            @rel_type = map { 'cjkvi:ids:' . $_ } @source;
          }
          my $c2 = (wrap_ids $ids, ':cjkvi:') // die $ids;
          for my $rel_type (@rel_type) {
            $Data->{idses}->{$c1}->{$c2}->{$rel_type} = 1;
          }
        }
      } # $c1
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  use utf8;
  my $path = $TempPath->child ('cjkvi-ids/waseikanji-ids.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    s/\s+#\s*$//g;
    if (/^([0-9]+[a-z]*)\t(〓)$/) {
      #
    } elsif (/^([0-9]+[a-z]*)\t(\S+)$/) {
      my $c1 = sprintf ':wasei%s', $1;
      my $c2 = (wrap_ids $2, ':cjkvi:') // die $2;
      $Data->{idses}->{$c1}->{$c2}->{'cjkvi:ids'} = 1;
    } elsif (/^([0-9]+[a-z]*)\t(\S+)\t# (\w)$/) {
      my $c1 = sprintf ':wasei%s', $1;
      my $c2 = (wrap_ids $2, ':cjkvi:') // die $2;
      my $c3 = $3;
      $Data->{idses}->{$c1}->{$c2}->{'cjkvi:ids'} = 1;
      $Data->{hans}->{$c1}->{$c3}->{'cjkvi:#'} = 1;
    } elsif (/^([0-9]+[a-z]*)\t(\S+)\t# (\w)≒(\w)$/) {
      my $c1 = sprintf ':wasei%s', $1;
      my $c2 = (wrap_ids $2, ':cjkvi:') // die $2;
      $Data->{idses}->{$c1}->{$c2}->{'cjkvi:#:ids'} = 1;
    } elsif (/^([0-9]+[a-z]*)\t(\S+)\t# \x{2466}\x{FF1D}\x{2939}(\w)$/) {
      my $c1 = sprintf ':wasei%s', $1;
      my $c2 = (wrap_ids $2, ':cjkvi:') // die $2;
      $Data->{idses}->{$c1}->{$c2}->{'cjkvi:#:ids'} = 1;
    } elsif (/^([0-9]+[a-z]*)\t(\S+)\t# (?:正確には|折れが).+$/) {
      my $c1 = sprintf ':wasei%s', $1;
      my $c2 = (wrap_ids $2, ':cjkvi:') // die $2;
      $Data->{idses}->{$c1}->{$c2}->{'cjkvi:#:ids'} = 1;
    } elsif (/^([0-9]+[a-z]*)\t(\S+)\t# (\p{Ideographic_Description_Characters}[\p{Ideographic_Description_Characters}\p{Han}]+)$/) {
      my $c1 = sprintf ':wasei%s', $1;
      my $c2 = (wrap_ids $2, ':cjkvi:') // die $2;
      my $c3 = (wrap_ids $3, ':cjkvi:') // die $3;
      $Data->{idses}->{$c1}->{$c2}->{'cjkvi:ids'} = 1;
      $Data->{idses}->{$c1}->{$c3}->{'cjkvi:#:ids'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $dir_path = $TempPath->child ('radically-ids/rawdata/manual_ids');
  for my $path (($dir_path->children (qr/\.txt$/))) {
    for (split /\x0D?\x0A/, $path->slurp_utf8) {
      if (/^U\+([0-9A-F]+)\t\S((?:\t\S+)+)$/) {
        my $c1 = u_chr hex $1;
        my @l = grep { length } split /\t/, $2;
        for (@l) {
          my $c2 = wrap_ids $_, ':radically:';
          $Data->{idses}->{$c1}->{$c2}->{'radically:ids'} = 1;
        }
      } elsif (/\S/) {
        die $_;
      }
    }
  }
}

{
  my $path = $TempPath->child ('ids-20230408.txt');
  {
    for (split /\x0D?\x0A/, $path->slurp_utf8) {
      if (/^U\+([0-9A-F]+)\s+\S((?:\s+\S+)+)\s*$/) {
        my $c1 = u_chr hex $1;
        my @l = grep { length } split /\s+/, $2;
        if ($l[-1] eq '~') {
          pop @l;
          @l = map { "\x{2FFB}" . $_ } @l;
        }
        for (@l) {
          my $c2 = wrap_ids $_, ':hkcs-';
          $Data->{idses}->{$c1}->{$c2}->{'hkcs:ids'} = 1;
        }
      } elsif (/\S/) {
        die $_;
      }
    }
  }
}

for (
  ['ids_lv0.txt', 'lv0'],
  ['ids_lv1.txt', 'lv1'],
  ['ids_lv2.txt', 'lv2'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $lv = $_->[1];
  {
    for (split /\x0D?\x0A/, $path->slurp_utf8) {
      if (/^(\S)\s+(\S+)(?:\s+(\S+)|)$/) {
        my $c1 = $1;
        my $primary = $2;
        my $alternative = $3;
        for (
          [$primary, $lv.':primary'],
          [$alternative, $lv.':alternative'],
        ) {
          my $rel_type = 'yaids:' . $_->[1];
          next unless defined $_->[0];
          for (split /;/, $_->[0]) {
            my $ids = $_;
            my $pp = '';
            next if $ids =~ /^\#\([A-Za-z]+\)$/;
            $pp = $1 if $ids =~ s/(?<!#)\(([A-Za-z0-9.,]*)\)$//;
            next if $ids eq '#' or $ids eq '*' or $ids eq '#()';

            my $c2 = wrap_ids $ids, ':yaids:';
            $Data->{idses}->{$c1}->{$c2}->{$rel_type} = 1;
          }
        }
      } elsif (/\S/) {
        die $_;
      }
    }
  }
}

{
  use utf8;
  my $path = $TempPath->child ('babel-ids.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^U\+([0-9A-F]+)\s+\S((?:\s+\S+)+)\s*$/) {
      my $c1 = u_chr hex $1;
      my @s = grep { length } split /\t/, $2;
      for my $s (@s) {
        if ($s =~ /^\^(.+)\$\(([A-Z0-9\[\]]+)\)$/) {
          my $ids = $1;
          my $sources = $2;
          my $c2 = (wrap_ids $ids, ':babel:');
          next if not defined $c2 and $ids eq "\x{FF1F}";

          my @source;
          while ($sources =~ s/\[(\w+)\]//g) {
            push @source, map { "[$_]" } split //, $1;
          }
          push @source, split //, $sources;
          if ($sources eq 'UCS2003') {
            @source = ($sources);
          } elsif ($sources =~ /UCS2003/) {
            die $sources;
          }

          for my $source (@source) {
            $Data->{idses}->{$c1}->{$c2}->{'babel:ids:'.$source} = 1;
          }
        } elsif ($s =~ s/^\*\s*(.+)$//) {
          my @t = split /;\s*/, $1;
          for my $t (@t) {
            if ($t =~ /^U\+([0-9A-F]+)(?:\([A-Z]+\)|)([=≠≡])U\+([0-9A-F]+)(?:\([A-Z]+\)|)$/) {
              my $c1 = u_chr hex $1;
              my $c2 = u_chr hex $3;
              $Data->{hans}->{$c1}->{$c2}->{'babel:'.$2} = 1;
            } elsif ($t =~ /^U\+([0-9A-F]+)([=≠≡])U\+([0-9A-F]+)\2U\+([0-9A-F]+)$/) {
              my $c1 = u_chr hex $1;
              my $c2 = u_chr hex $3;
              my $c3 = u_chr hex $4;
              $Data->{hans}->{$c1}->{$c2}->{'babel:'.$2} = 1;
              $Data->{hans}->{$c1}->{$c3}->{'babel:'.$2} = 1;
            } elsif ($t =~ /^U\+([0-9A-F]+)([=≠≡])U\+([0-9A-F]+)\2U\+([0-9A-F]+)\2U\+([0-9A-F]+)$/) {
              my $c1 = u_chr hex $1;
              my $c2 = u_chr hex $3;
              my $c3 = u_chr hex $4;
              my $c4 = u_chr hex $5;
              $Data->{hans}->{$c1}->{$c2}->{'babel:'.$2} = 1;
              $Data->{hans}->{$c1}->{$c3}->{'babel:'.$2} = 1;
              $Data->{hans}->{$c1}->{$c4}->{'babel:'.$2} = 1;
            } elsif ($t =~ /^U\+([0-9A-F]+)\([A-Z]+\) was \^([^\$]+)\$ (?:\[=U\+[0-9A-F]+(?:\([A-Z]+\)|)\] |)(?:before|in) [Uu]nicode [0-9]+\.[0-9]+(?: only|)$/) {
              my $c1 = u_chr hex $1;
              my $ids = $2;
              my $c2 = (wrap_ids $ids, ':babel:') // die $ids;
              $Data->{idses}->{$c1}->{$c2}->{'babel:ids'} = 1;
            } elsif ($t =~ /^ROK source shows \^([^\$]+)\$/) {
              my $ids = $1;
              my $c2 = (wrap_ids $ids, ':babel:') // die $ids;
              $Data->{idses}->{$c1}->{$c2}->{'babel:ids'} = 1;
            } elsif ($t =~ /^KX-([0-9]+)\.([0-9]{2}) has \^([^\$]+)\$$/) {
              my $c1 = sprintf ':kx%d-%d', $1, $2;
              my $ids = $3;
              my $c2 = (wrap_ids $ids, ':babel:') // die $ids;
              $Data->{idses}->{$c1}->{$c2}->{'babel:ids'} = 1;
            } elsif ($t =~ /^(UK-[0-9]+|GXM-[0-9]+) \^([^\$]+)\$ unified to U\+([0-9A-F]+)$/) {
              my $c1 = u_chr hex $3;
              my $c3 = ':' . $1;
              my $ids = $2;
              my $c2 = (wrap_ids $ids, ':babel:') // die $ids;
              $Data->{idses}->{$c1}->{$c2}->{'babel:ids'} = 1;
              $Data->{idses}->{$c3}->{$c2}->{'babel:ids'} = 1;
            } elsif ($t =~ /^U\+(3777)\(T\) was \^([^\$]+)\$ before Unicode 6\.0, and \^([^\$]+)\$ between Unicode 6\.0 and 13\.0 inclusive$/) {
              my $c1 = u_chr hex $1;
              my $ids1 = $2;
              my $c2 = (wrap_ids $ids1, ':babel:') // die $ids1;
              my $ids2 = $3;
              my $c3 = (wrap_ids $ids2, ':babel:') // die $ids2;
              $Data->{idses}->{$c1}->{$c2}->{'babel:ids'} = 1;
              $Data->{idses}->{$c1}->{$c3}->{'babel:ids'} = 1;
            } elsif ($t =~ /^and \^([^\$]+)\$ = U\+20D01\(G\) in Unicode 6.0$/) {
              my $ids1 = $1;
              my $c2 = (wrap_ids $ids1, ':babel:') // die $ids1;
              $Data->{idses}->{$c1}->{$c2}->{'babel:ids'} = 1;
            } elsif ($t =~ /^KX-(1436)\.(08) has (\S+) but that is an error for (\S+)$/) {
              my $c1 = sprintf ':kx%d-%d', $1, $2;
              my $ids1 = $3;
              my $c2 = (wrap_ids $ids1, ':babel:') // die $ids1;
              my $ids2 = $4;
              my $c3 = (wrap_ids $ids2, ':babel:') // die $ids2;
              $Data->{idses}->{$c1}->{$c2}->{'babel:ids'} = 1;
              $Data->{hans}->{$c1}->{':'.$c3}->{'manakai:related'} = 1;
            } elsif ($t eq 'GB 18030-2022 shows the Z-form' or
                     $t eq 'GB 18030-2022 shows the first Z-form') {
              #
            } else {
              #warn $t;
              #die $t;
            }
          } # $t
        }
      }
    } elsif (/^#\t(\{[0-9]+\})\t[^\t]+\t(\S+)$/) {
      my $c1 = sprintf ':babel:%s', $1;
      my $ids = $2;
      my $c2 = wrap_ids $ids, ':babel:';
      next if not defined $c2 and $ids eq "\x{FF1F}";
      $Data->{idses}->{$c1}->{$c2}->{'babel:ids'} = 1;
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}

write_rel_data_sets
    $Data => $ThisPath, 'ids',
    [
      qr/[\x{3000}-\x{4FFF}]/,
      qr/[\x{5000}-\x{6FFF}]/,
      qr/[\x{7000}-\x{8FFF}]/,
      qr/[\x{20000}-\x{22FFF}]/,
      qr/[\x{23000}-\x{25FFF}]/,
      qr/[\x{26000}-\x{28FFF}]/,
      qr/[\x{29000}-\x{2BFFF}]/,
      qr/[\x{2C000}-\x{2FFFF}]/,
      qr/[\x{30000}-\x{3FFFF}]/,
      qr/^:/,
    ];

## License: Public Domain.
