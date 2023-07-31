use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwm');
my $DataPath = $RootPath->child ('local/generated/charrels/glyphs/gwglyphs');
my $Index = {};
$Index->{timestamp} = time;

{
  my $to_index = {};
  my $PrefixPattern;
  {
    my $prefixes = [qw(
      a
      c
      e
      g
      h hangul hd hkcs hkcs_m hkcs_m1 hkcs_m2 hkcs_m3 hkcs_m9 hkcs_mf
      i
      j
      k ka kx
      s sa si sim- simch-hangul simch-kx_t0 simch-kx_t1
      simch-supercjk simch-supercjk_u1 simch-supercjk_u2 simch-supercjk_u3
      simch-supercjk_u8 simch-supercjk_u9 simch-supercjk_uf
      t
      u u1 u2 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u2a u2b u2c u2d u2e u2f
      u2ff0 u2ff1 u2ff2 u2ff3 u2ff4 u2ff5 u2ff6 u2ff7 u2ff8 u2ff9
      u3 u4 u5 u6 u7 u8 u9 ue uf unstable utc
      v w
      z z-sat
    )];
    my $x = 0x500;
    $to_index->{$_} = $x++ for @$prefixes;
    $Index->{prefix_to_index} = $to_index;

    $Index->{prefix_pattern} =
    $PrefixPattern = join '|', sort { (length $b) <=> (length $a) || $a cmp $b } @$prefixes;
  }

  sub char_to_index ($) {
    my $c1 = $_[0];
    if ($c1 =~ /\A($PrefixPattern)/o) {
      return $to_index->{$1} // die $1;
    } elsif ($c1 =~ /([0-9a-f]+)/) {
      return 0x100 + (hex $1) % 10;
    }
    return 0;
  } # char_to_index
  
  sub insert ($$$) {
    my ($char, $data => $out_files) = @_;

    my $index = char_to_index $char;

    push @{$out_files->[$index] ||= []}, $data;
  } # insert
}

my $OutFiles = [];
{
  my $in_path = $TempPath->child ('dump_newest_only.txt');
  my $in_file = $in_path->openr;

  my $related_path = $TempPath->child ('gwrelated.txt');
  my $related_file = $related_path->openw;
  my $alias_path = $TempPath->child ('gwalias.txt');
  my $alias_file = $alias_path->openw;
  my $contains_path = $TempPath->child ('gwcontains.txt');
  my $contains_file = $contains_path->openw;
  
  my @header;
  while (<$in_file>) {
    if (/^--[-+]+$/) {
      #
    } elsif (/^\(/) {
      #
    } elsif (/^ ([^|]+)\|([^|]+)\|([^|]+)$/) {
      my $v1 = $1;
      my $v2 = $2;
      my $v3 = $3;
      s/^\s+// for ($v1, $v2, $v3);
      s/\s+$// for ($v1, $v2, $v3);
      if (@header) {
        my $value = {};
        $value->{$header[0]} = $v1;
        $value->{$header[1]} = $v2;
        $value->{$header[2]} = $v3;

        if ($value->{data} =~ /^99:0:0:0:0:200:200:([^:]+)$/) {
          print $alias_file "$value->{name}\t$1\n";
        } else {
          insert $value->{name}, [$value->{name} => $value->{data}] => $OutFiles;
          for (grep { not /^-?[0-9]+(?:\$[0-9]+|)$/ } split /:/, $value->{data}) {
            my $x = $_;
            $x =~ s/\$[0-9]+$//;
            print $contains_file "$value->{name}\t$x\n";
          }
        }
        
        if (not ($value->{related} eq 'u3013')) {
          print $related_file "$value->{name}\t$value->{related}\n";
        }
      } else {
        push @header, $v1, $v2, $v3;
      }
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  $DataPath->mkpath;
  for my $path (($DataPath->children (qr/^part-[0-9]+\.jsonl$/))) {
    $path->remove;
  }
  my $all = @$OutFiles;
  for my $i (0..$#$OutFiles) {
    next unless defined $OutFiles->[$i];
    next unless @{$OutFiles->[$i]};

    print STDERR "\rWriting[$i/$all] (@{[0+@{$OutFiles->[$i]}]})... ";
    my $path = $DataPath->child ("part-$i.jsonl");
    my $file = $path->openw;
    
    @{$OutFiles->[$i]} = sort { $a->[0] cmp $b->[0] } @{$OutFiles->[$i]};
    for (@{$OutFiles->[$i]}) {
      print $file perl2json_bytes $_;
      print $file "\x0A";
    }
  } # $i

  {
    my $path = $DataPath->child ("index.json");
    my $file = $path->openw;
    print $file perl2json_bytes $Index;
  }
}
print STDERR "\n";

## License: Public Domain.
