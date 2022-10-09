use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;

{
  my $to_index = {};
  {
    my $x = 0x50;
    $to_index->{$_} = $x++ for qw(MJ ac ag aj ak aj2- ak1-
                                  jis cns gb ks cjkvi swc);
  }

  sub char_to_index ($) {
    my $c1 = $_[0];
    my $c1l = length $c1;
    if ($c1l == 1) {
      my $c = ord $c1;
      if ($c <= 0x10FFFF) {
        return 1 + int ($c / 0x2000);
      }
    } elsif ($c1l == 2) {
      my $vs = ord substr $c1, 1;
      if (0xE0100 <= $vs and $vs <= 0xE01FF) {
        return $vs - 0xE0000;
      } else {
        return 0x40;
      }
    } elsif ($c1 =~ /\A:(MJ|ac|ag|aj|ak|aj2-|ak1-|jis|cns|gb|ks|cjkvi|swc)/) {
      return $to_index->{$1} // die $1;
    } elsif ($c1 =~ /^:u-/) {
      return 0x4F;
    } elsif (3 <= $c1l and $c1l <= 10) {
      return 0x40 - 2 + $c1l;
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
  'char-cluster-indexed' => {
  },
  'char-leaders' => {
  },
  'merged-rels' => {
    paired => 1,
  },
}->{$FileKey} or die "Bad file-key |$FileKey|";

my $OutFiles = [];
{
  my $ext = $FileDef->{paired} ? 'jsonll' : 'jsonl';
  my $path = $DataPath->child ("$FileKey.$ext");
  print STDERR "\rLoading |$path|...";
  my $file = $path->openr;
  if ($FileDef->{paired}) {
    local $/ = "\x0A\x0A";
    while (<$file>) {
      my $c1 = json_bytes2perl $_;
      my $c1v = json_bytes2perl scalar <$file>;
      insert $c1, [$c1 => $c1v] => $OutFiles;
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
  for my $i (1..$#$OutFiles) {
    next unless defined $OutFiles->[$i];
    if (@{$OutFiles->[$i]} < 100) {
      push @{$OutFiles->[0] ||= []}, @{delete $OutFiles->[$i]};
    }
  }

  my $ext = $FileDef->{paired} ? 'jsonll' : 'jsonl';
  for my $path (($DataPath->children (qr/^\Q$FileKey\E-part-[0-9]+\.\Q$ext\E$/))) {
    $path->remove;
  }
  for my $i (0..$#$OutFiles) {
    next unless defined $OutFiles->[$i];
    next unless @{$OutFiles->[$i]};

    print STDERR "\rWrite[$i]...";
    my $path = $DataPath->child ("$FileKey-part-$i.$ext");
    my $file = $path->openw;

    print STDERR " (@{[0+@{$OutFiles->[$i]}]})";
    if ($FileDef->{paired}) {
      @{$OutFiles->[$i]} = sort { $a->[0] cmp $b->[0] } @{$OutFiles->[$i]};
      for (@{$OutFiles->[$i]}) {
        print $file perl2json_bytes_for_record $_->[0]; # trailing \x0A
        print $file "\x0A";
        print $file perl2json_bytes_for_record $_->[1]; # trailing \x0A
        print $file "\x0A";
      }
    } else {
      @{$OutFiles->[$i]} = sort { $a->[0] cmp $b->[0] } @{$OutFiles->[$i]};
      for (@{$OutFiles->[$i]}) {
        print $file perl2json_bytes $_;
        print $file "\x0A";
      }
    }
  } # $i
}

printf STDERR "\rDone (%d s) \n", time - $StartTime;

## License: Public Domain.
