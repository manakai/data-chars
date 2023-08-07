use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' }

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iemacs');

my $Data = {};

for (
  ['usisheng.el', "\x28\x30", ':omronzh-', ''],
  ['uiscii.el', "\x28\x35", ':iscii-', ':iscii'],
  ['ulao.el', "\x28\x31", ':mulelao-', ''],
  ['uipa.el', "\x2C\x30", ':muleipa-', ''],
) {
  my ($file_name, $final, $prefix, $suffix) = @$_;
  my $path = $TempPath->child ('mule-ucs/lisp/reldata/' . $file_name);
  my $file = $path->openr;
  while (<$file>) {
    if (/^;/) {
      #
    } elsif (/^\s*\(+\?\x1B\Q$final\E(.)\x1B\x28B\s*\.\s*"0x([0-9A-Fa-f]+)"\)/) {
      my $c1 = sprintf '%s%x', $prefix, ord $1;
      my $c2 = chr hex $2;
      my $vkey = get_vkey $c2;
      $Data->{$vkey}->{$c1}->{$c2}->{'emacs:reldata'.$suffix} = 1;
    } elsif (/^\s*;+\(+\?\x1B\Q$final\E(.)\x1B\x28B\s*\.\s*\?\\x\)\s*;+[^(]+\(U\+([0-9A-F]+)\)[^(]+\(U\+([0-9A-F]+)\)\s*$/) {
      my $c1 = sprintf '%s%x', $prefix, ord $1;
      my $c2 = (chr hex $2) . (chr hex $3);
      my $vkey = get_vkey $c2;
      $Data->{$vkey}->{$c1}->{$c2}->{'emacs:reldata:;'.$suffix} = 1;
    } elsif (/\x1B/) {
      die $_;
    }
  }
}

for (
  ['uviscii.el'],
) {
  my ($file_name) = @$_;
  my $path = $TempPath->child ('mule-ucs/lisp/reldata/' . $file_name);
  my $file = $path->openr;
  while (<$file>) {
    if (/^;/) {
      #
    } elsif (/^\s*\(+\?\x1B\x2C([12])(.)\x1B\x28B\s*\.\s*"0x([0-9A-Fa-f]+)"\)/) {
      my $c1 = sprintf ':muleviscii%d-%x', $1, ord $2;
      my $c2 = chr hex $3;
      my $vkey = get_vkey $c2;
      $Data->{$vkey}->{$c1}->{$c2}->{'emacs:reldata'} = 1;
    } elsif (/\x1B/) {
      die $_;
    }
  }
}

for (
  ['uethiopic.el', "\x33", ':muleethiopic-', ''],
  ['utibetan.el', "\x37", ':muletibetan2-', ''],
) {
  my ($file_name, $final, $prefix, $suffix) = @$_;
  my $path = $TempPath->child ('mule-ucs/lisp/reldata/' . $file_name);
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*\(+\?\x1B\x24\x28\Q$final\E(.)(.)\x1B\x28B\s*\.\s*"0x([0-9A-F]+)"\)/) {
      my $c1 = sprintf '%s%d-%d', $prefix, (ord $1)-0x20, (ord $2)-0x20;
      my $c2 = chr hex $3;
      my $vkey = get_vkey $c2;
      $Data->{$vkey}->{$c1}->{$c2}->{'emacs:reldata'.$suffix} = 1;
    } elsif (/^\s*\(+\?\x1B4\x1B\x24\x28\Q$final\E(.)(.)\x1B0(.)(.)\x1B1\x1B\x28B\s*\.\s*"0x([0-9A-F]+)"\)/) {
      my $c1 = sprintf ':muleesc-34%s%d-%d:muleesc-30%s%d-%d:muleesc-31',
          $prefix, (ord $1)-0x20, (ord $2)-0x20,
          $prefix, (ord $3)-0x20, (ord $4)-0x20;
      my $c2 = chr hex $5;
      my $vkey = get_vkey $c2;
      $Data->{$vkey}->{$c1}->{$c2}->{'emacs:reldata'.$suffix} = 1;
    } elsif (/^\s*;;\s*Composite/) {
      #
    } elsif (/\x1B/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('cgreek-2/site-lisp/cgreek/cgreek.el');
  my $text = $path->slurp;
  $text =~ m{\[(\s*0\s+1\s+2\s+.+?\s+254\s+255\s*)\]}s or die;
  my $x = $1;
  $x =~ s/\s+$//;
  my $i = 0;
  while (length $x) {
    if ($x =~ s/^\s*([0-9]+)//) {
      die "$1 / $i" unless $1 == $i;
    } elsif ($x =~ s/^\s*\?\x1B\x24,4(.)(.)\x1B\x28B//) {
      my $c1 = sprintf ':wingreek-%x', $i;
      my $c2 = sprintf ':mulecgreek-%x', (ord $1) * 0x100 + (ord $2);
      $Data->{variants}->{$c1}->{$c2}->{'emacs:ccl-decode-cgreek'} = 1;
    } else {
      die "Bad line |$x|";
    }
    $i++;
  }
}
{
  my $path = $TempPath->child ('cgreek-2/site-lisp/cgreek/cgreek-util.el');
  my $text = $path->slurp;
  {
    $text =~ m{cgreek-to-tex-table\s*\[(.+?)\]\)}s or die;
    my $x = $1;
    $x =~ s/\s+$//;
    $x =~ s{\s+;.+$}{}gm;
    my $i = 0;
    while (length $x) {
      if ($x =~ s/^\s*nil\b//) {
        #
      } elsif ($x =~ s/^\s*" "//) {
        #
      } elsif ($x =~ s/^\s*"([^"]+)"//) {
        my $c1 = sprintf ':wingreek-%x', $i;
        my $c2 = $1;
        $c2 =~ s/\\(.)/$1/gs;
        $c2 = wrap_string $c2;
        $Data->{descs}->{$c1}->{$c2}->{'emacs:cgreek-to-tex-table'} = 1;
      } else {
        die "Bad line |$x|";
      }
      $i++;
    }
  }
  {
    $text =~ m{cgreek-latin1-to-tex-table\s*\[(.+?)\]\)}s or die;
    my $x = $1;
    $x =~ s/\s+$//;
    $x =~ s{\s+;.+$}{}gm;
    my $i = 0;
    while (length $x) {
      if ($x =~ s/^\s*nil\b//) {
        #
      } elsif ($x =~ s/^\s*" "//) {
        #
      } elsif ($x =~ s/^\s*([0-9]+)//) {
        my $c1 = sprintf ':isolatin1-%x', $i;
        my $c2 = sprintf ':ascii-%x', $1;
        $Data->{descs}->{$c1}->{$c2}->{'emacs:cgreek-latin1-to-tex-table'} = 1;
      } elsif ($x =~ s/^\s*"((?>[^"\\]|\\.)+)"//) {
        my $c1 = sprintf ':isolatin1-%x', $i;
        my $c2 = $1;
        $c2 =~ s/\\(.)/$1/gs;
        $c2 = wrap_string $c2;
        $Data->{descs}->{$c1}->{$c2}->{'emacs:cgreek-latin1-to-tex-table'} = 1;
      } else {
        die "Bad line |$x|";
      }
      $i++;
    }
  }
  {
    $text =~ m{cgreek-simple-table\s*\[(.+?)\]\s*"}s or die;
    my $x = $1;
    $x =~ s/\s+$//;
    $x =~ s{\s+;.+$}{}gm;
    my $i = 0;
    while (length $x) {
      my $c1 = sprintf ':wingreek-%x', $i;
      if ($x =~ s/^\s*(?:nil|32)\b//) {
        #
      } elsif ($x =~ s/^\s*\?\\t//) {
        my $c2 = sprintf ':ascii-%x', 0x09;
        $Data->{variants}->{$c1}->{$c2}->{'emacs:cgreek-simple-table'} = 1;
      } elsif ($x =~ s/^\s*\?\\n//) {
        my $c2 = sprintf ':ascii-%x', 0x0A;
        $Data->{variants}->{$c1}->{$c2}->{'emacs:cgreek-simple-table'} = 1;
      } elsif ($x =~ s/^\s*\?\\"//) {
        my $c2 = sprintf ':ascii-%x', 0x22;
        $Data->{variants}->{$c1}->{$c2}->{'emacs:cgreek-simple-table'} = 1;
      } elsif ($x =~ s/^\s*\?([\x21-\x7E])//) {
        my $c2 = sprintf ':ascii-%x', ord $1;
        $Data->{variants}->{$c1}->{$c2}->{'emacs:cgreek-simple-table'} = 1;
      } elsif ($x =~ s/^\s*\?\x1B\x24,4(.)(.)\x1B\x28B//) {
        my $c2 = sprintf ':mulecgreek-%x', (ord $1) * 0x100 + (ord $2);
        $Data->{variants}->{$c1}->{$c2}->{'emacs:cgreek-simple-table'} = 1;
      } else {
        die "Bad line |$x|";
      }
      $i++;
    }
  }
}
{
  my $path = $TempPath->child ('cgreek-2/site-lisp/cgreek/cgreek-quail.el');
  my $text = $path->slurp;
  my $package;
  my $in_rules = 0;
  for (split /\x0A/, $text) {
    if (m{^\s*\(quail-define-package "([^"]+)" }) {
      $package = $1;
    } elsif (m{^\s*\(quail-define-rules\s*$}) {
      $in_rules = 1;
    } elsif ($in_rules) {
      if (/^(\s*;+|)(?:\s+\("((?>[^"\\]|\\.)+)"\s+(?:\?\x1B\x24,4..\x1B\x28B|\?\x1B,A.\x1B\x28B|\["\x1B\x24,4....\x1B\x28B"\]|\["\x1B\x24,4..\x1B\x28B."\])\))+\s*(?:;.*|)$/) {
        my $in_comment = !! s/^\s*;+\s*//;
        while (s/^\s*\("((?>[^"\\]|\\.)+)"\s+(?:\?\x1B\x24,4(.)(.)\x1B\x28B|\?\x1B,A(.)\x1B\x28B|\["\x1B\x24,4(.)(.)(.)(.)\x1B\x28B"\]|\["\x1B\x24,4(.)(.)\x1B\x28B(.)"\])\)//) {
          my $c1 = wrap_string $1;
          my $c2;
          if (defined $2) {
            $c2 = sprintf ':mulecgreek-%x', (ord $2) * 0x100 + (ord $3);
          } elsif (defined $4) {
            $c2 = sprintf ':isolatin1-%x', ord $4;
          } elsif (defined $5) {
            $c2 = sprintf ':mulecgreek-%x:mulecgreek-%x',
                (ord $5) * 0x100 + (ord $6),
                (ord $7) * 0x100 + (ord $8);
          } elsif (defined $9) {
            $c2 = sprintf ':mulecgreek-%x:ascii-%x',
                (ord $9) * 0x100 + (ord $10),
                (ord $11);
          } else {
            die $_;
          }
          $c1 =~ s/\\(.)/$1/g;
          my $rel_type = 'emacs:quail:'.$package;
          $rel_type .= ':;' if $in_comment;
          $Data->{descs}->{$c1}->{$c2}->{$rel_type} = 1;
        }
        s/^\s*;.*//;
        die if length $_;
      } elsif (/^\s*;\s*\(\s*""/) {
        #
      } elsif (/^\s*\)\s*$/) {
        $in_rules = 0;
      } elsif (/\S/) {
        die "Bad line |$_|";
      }
    }
  }
}

{
  my $path = $TempPath->child ('cgreek23/cgreek-misc.el');
  my $text = $path->slurp;
  $text =~ /\[(\s+#x[^\[\]]+)\]/s or die;
  my $v = $1;
  my $i = 0;
  while ($v =~ s/^\s+#x([0-9A-Fa-f]+)//) {
    my $c1 = sprintf ':wingreek-%x', $i;
    my $c2 = u_chr hex $1;
    my $rel_type = 'emacs:greek-wingreek-to-unicode-table';
    my $vkey = get_vkey $c2;
    $Data->{$vkey}->{$c1}->{$c2}->{$rel_type} = 1;
    $i++;
  }
  $v =~ s/^\s+//;
  die $v if length $v;
}
for (
  'greek.el',
  'latin.el',
  'russian.el',
) {
  my $name = $_;
  my $path = $TempPath->child ('cgreek23/' . $name);
  my $text = $path->slurp_utf8;
  my $package;
  my $in_package = 0;
  my $in_rules = 0;
  for (split /\x0A/, $text) {
    if (m{^\s*\(robin-define-package "([^"]+)"}) {
      $package = $1;
      $in_package = 1;
    } elsif ($in_package) {
      if (/^\s*"[^"]+$/ or /^(?>[^"\\]|\\"|\\\\)+$/) {
        #
      } elsif (/^[^"]*"\s*$/) {
        $in_rules = 1;
        $in_package = 0;
      } elsif (/^\s*"[^"]+"\s*$/) {
        $in_rules = 1;
        $in_package = 0;
      } elsif (length) {
        die "Bad line |$_|";
      }
    } elsif ($in_rules) {
      if (/^(\s*;+|)(?:\s+\("((?>[^"\\]|\\.)+)"\s+(?:\?[^\\]|"[^"\\]+"|\?\\[()\\";,])\))+\s*(?:;.*|)$/) {
        my $in_comment = !! s/^\s*;+\s*//;
        while (s/^\s*\("((?>[^"\\]|\\.)+)"\s+(?:\?([^\\])|"([^"\\]+)"|\?\\([()\\";,]))\)//) {
          my $c1 = wrap_string $1;
          my $c2;
          if (defined $2) {
            $c2 = wrap_string $2;
          } elsif (defined $3) {
            $c2 = wrap_string $3;
          } elsif (defined $4) {
            $c2 = wrap_string $4;
          } else {
            die;
          }
          $c1 =~ s/\\(.)/$1/g;
          my $rel_type = 'emacs:robin:'.$package;
          $rel_type .= ':;' if $in_comment;
          $Data->{descs}->{$c1}->{$c2}->{$rel_type} = 1
              unless $c1 eq $c2;
        }
        s/^\s*;.*//;
        die "Bad line |$_|" if length $_;
      } elsif (/^\s*\("\?" \?,\)\)\s*$/) {
        my $c1 = wrap_string "?";
        my $c2 = wrap_string ",";
        my $rel_type = 'emacs:robin:'.$package;
        $Data->{descs}->{$c1}->{$c2}->{$rel_type} = 1;
        $in_rules = 0;
      } elsif (/^\s*\("\?" \?\?\)\)\s*$/) {
        #my $c1 = wrap_string "?";
        #my $c2 = wrap_string "?";
        $in_rules = 0;
      } elsif (/^\s*;\s*\(\s*""/) {
        #
      } elsif (/^\s*;+\s*[A-Z]/) {
        #
      } elsif (/^\s*\)\s*$/) {
        $in_rules = 0;
      } elsif (/\S/) {
        die "Bad line |$_|";
      }
    }
  }
}

write_rel_data_sets
    $Data => $ThisPath, 'maps',
    [];

## License: Public Domain.
