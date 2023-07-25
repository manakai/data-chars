use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;
my $Index = {};

{
  my $to_index = {};
  my $PrefixPattern;
  {
    my $prefixes = [qw(
      MJ MJ00 MJ000 MJ001 MJ002 MJ003 MJ004 MJ005 MJ006
      MJ01 MJ010 MJ011 MJ012 MJ013 MJ014 MJ015
      MJ02 MJ020 MJ021 MJ022 MJ023 MJ024 MJ025
      MJ030 MJ031 MJ032 MJ033 MJ034 MJ035 MJ036 MJ037 MJ038 MJ039
      MJ04 MJ040 MJ041 MJ042 MJ043 MJ044
      MJ05 MJ050 MJ051 MJ052 MJ053 MJ054
      MJ06
      ac ac1 ac2 ag ag1 ag2
      aj1 aj11 aj12 aj13 aj14 aj15 aj16 aj17 aj18 aj19
      aj2 aj3 aj4 aj5 aj6 aj7 aj8 aj9 aj aj2-1 aj2-
      ak ak1 ak2 ak1-
      jis1 jis1-1 jis1-2 jis1-3 jis1-4 jis1-5 jis1-6 jis1-7 jis1-8 jis1-9
      jis2 jis2-1 jis2-2 jis2-3 jis2-4 jis2-5 jis2-6 jis2-7 jis2-8 jis2-9
      jis-arib u-arib
      cns cns-old cns1 cns1-1 cns2 cns2-1 cns3 cns3-1 cns4 cns4-1
      cns5 cns6 cns7 cns8 cns9 cns10 cns11 cns12 cns13 cns14 cns15
      cns16 cns17 cns18 cns19 u-cns u-cns-f0 u-cns-f1 u-cns-f2 u-cns-f3
      u-cns-f6 u-cns-fd u-cns-ff
      gb0 gb0-1 gb0-2 gb1 gb2 gb3 gb8 gb u-gb
      ks kps cjkvi
      UK u-uk
      swc tron
      b5 b5-8 b5-9 b5-a b5-b b5-c b5-d b5-e b5-f b5-hkscs b5-uao b5-cdp 
      u-bigfive u-hkscs u-uao
      cccii cccii1 cccii2 cccii3 cccii4 cccii9
      koseki koseki0 koseki1 koseki2 koseki3 koseki4 koseki5 touki
      KS KS0 KS1 KS2 KS3 TK J JA JB JC JD JT I
      m m1 m2 m3 m4 F G I
      kx kx0 kx1
    )];
    my $x = 0x500;
    $to_index->{$_} = $x++ for @$prefixes;
    $Index->{prefix_to_index} = $to_index;

    $Index->{prefix_pattern} =
    $PrefixPattern = join '|', sort { (length $b) <=> (length $a) || $a cmp $b } @$prefixes;
  }

  sub char_to_index ($) {
    my $c1 = $_[0];
    my $c1l = length $c1;
    if ($c1l == 1) {
      my $c = ord $c1;
      if ($c <= 0x10FFFF) {
        return 1 + int ($c / 0x200);
      }
    } elsif ($c1l == 2) {
      my $code1 = ord $c1;
      my $x = $code1 % 2 ? 0x100 : 0;
      my $vs = ord substr $c1, 1;
      if (0xE0100 <= $vs and $vs <= 0xE01FF) {
        return $vs - 0xE0000 + $x;
      } else {
        return 0xFF;
      }
    } elsif ($c1 =~ /\A:($PrefixPattern)/o) {
      return $to_index->{$1} // die $1;
    } elsif ($c1 =~ /^:u-/) {
      return 0x300;
    } elsif (3 <= $c1l and $c1l <= 10) {
      return 0x400 - 2 + $c1l;
    }

    return 0;
  } # char_to_index
  
  sub insert ($$$) {
    my ($char, $data => $out_files) = @_;

    my $index = char_to_index $char;

    push @{$out_files->[$index] ||= []}, $data;
  } # insert
}

my $FileKey = shift;
my $FileDef = {
  'char-cluster' => {
  },
  'char-leaders' => {
  },
  'merged-rels' => {
    paired => 1,
  },
}->{$FileKey} or die "Bad file-key |$FileKey|";

if ($FileKey eq 'merged-rels') {
  my $path = $DataPath->child ('merged-index.json');
  my $json = json_bytes2perl $path->slurp;
  $Index = {%$Index, %$json};

  my $n = 0;
  for my $rel (sort { $a cmp $b } keys %{$Index->{rel_types}}) {
    $Index->{rel_types}->{$rel}->{id} = $n++;
  }

  $Index->{timestamp} = time;
}

my $OutFiles = [];
{
  my $ext = $FileDef->{paired} ? 'jsonll' : 'jsonl';
  my $path = $DataPath->child ("$FileKey.$ext");
  print STDERR "\rLoading |$path|... ";
  my $file = $path->openr;
  if ($FileDef->{paired}) {
    local $/ = "\x0A\x0A";
    while (<$file>) {
      my $c1 = json_bytes2perl $_;
      my $c1v = json_bytes2perl scalar <$file>;

      my $value = {};
      for my $c2 (sort { $a cmp $b } keys %$c1v) {
        $value->{$c2} = [];
        for my $rel (sort { $a cmp $b } keys %{$c1v->{$c2}}) {
          next if $rel eq '_' or $rel eq '_u';
          push @{$value->{$c2}}, $Index->{rel_types}->{$rel}->{id};
          $Index->{rel_types}->{$rel}->{_n}++;
        }
      }
      
      insert $c1, [$c1 => $value] => $OutFiles;
    }
  } else {
    local $/ = "\x0A";
    while (<$file>) {
      my $json = json_bytes2perl $_;
      insert $json->[0], $json => $OutFiles;
    }
  }
}

{
  #for my $i (1..$#$OutFiles) {
  #  next unless defined $OutFiles->[$i];
  #  if (@{$OutFiles->[$i]} < 100) {
  #    push @{$OutFiles->[0] ||= []}, @{delete $OutFiles->[$i]};
  #  }
  #}

  $DataPath->child ($FileKey)->mkpath;
  my $ext = $FileDef->{out_paired} ? 'jsonll' : 'jsonl';
  for my $path (($DataPath->child ($FileKey)->children (qr/^part-[0-9]+\.\Q$ext\E$/))) {
    $path->remove;
  }
  my $all = @$OutFiles;
  for my $i (0..$#$OutFiles) {
    next unless defined $OutFiles->[$i];
    next unless @{$OutFiles->[$i]};

    print STDERR "\rWriting[$i/$all] (@{[0+@{$OutFiles->[$i]}]})... ";
    my $path = $DataPath->child ("$FileKey/part-$i.$ext");
    my $file = $path->openw;
    
    if ($FileDef->{out_paired}) {
      @{$OutFiles->[$i]} = sort { $a->[0] cmp $b->[0] } @{$OutFiles->[$i]};
      if ($FileDef->{pretty}) {
        for (@{$OutFiles->[$i]}) {
          print $file perl2json_bytes_for_record $_->[0]; # trailing \x0A
          print $file "\x0A";
          print $file perl2json_bytes_for_record $_->[1]; # trailing \x0A
          print $file "\x0A";
        }
      } else {
        for (@{$OutFiles->[$i]}) {
          print $file perl2json_bytes $_->[0];
          print $file "\x0A";
          print $file perl2json_bytes $_->[1];
          print $file "\x0A";
        }
      }
    } else {
      @{$OutFiles->[$i]} = sort { $a->[0] cmp $b->[0] } @{$OutFiles->[$i]};
      for (@{$OutFiles->[$i]}) {
        print $file perl2json_bytes $_;
        print $file "\x0A";
      }
    }
  } # $i

  {
    $Index->{rel_types} = {map {
      if (delete $Index->{rel_types}->{$_}->{_n}) {
        ($_ => $Index->{rel_types}->{$_});
      } else {
        ();
      }
    } keys %{$Index->{rel_types}}};

    my $path = $DataPath->child ("$FileKey/index.json");
    my $file = $path->openw;
    print $file perl2json_bytes $Index;
  }
}

printf STDERR "\rDone (%d s) \n", time - $StartTime;

## License: Public Domain.
