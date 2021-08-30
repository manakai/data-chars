use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/icjkvi');

my $Data = {};

sub wrap ($) {
  my $s = shift;
  $s = ':cjkvi:'.$s
      if $s =~ /\p{Ideographic_Description_Characters}|\[/;
  return $s;
} # wrap

{
  my $path = $TempPath->child ('variants.txt');
  my $vtype = 'cjkvi:variants';
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    if (/^(\w)(\w)$/) {
      $Data->{variants}->{$1}->{$2}->{$vtype} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $TempPath->child ('repo', 'jp-old-style.txt');
  my $vtype = 'cjkvi:jp-old-style';
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^(\w+)\t(\w+)$/) {
      $Data->{variants}->{$1}->{$2}->{$vtype} = 1;
    } elsif (/^(\w+)\t(\w+)\t(\w+)$/) {
      $Data->{variants}->{$1}->{$2}->{$vtype} = 1;
      $Data->{variants}->{$1}->{$3}->{"$vtype:compatibility"} = 1;
    } elsif (/^(\w+)\t\t\t# (\w+)$/) {
      $Data->{variants}->{$1}->{$2}->{"$vtype:comment"} = 1;
    } elsif (/^(\w+)\t(\w+)\t\t# \x{2605}$/) {
      $Data->{variants}->{$1}->{$2}->{$vtype} = 1;
    } elsif (/^(\w+)\t(\w+)\t\t# ([\w\p{Ideographic_Description_Characters}]+)$/) {
      $Data->{variants}->{$1}->{$2}->{$vtype} = 1;
      $Data->{variants}->{$1}->{wrap $3}->{"$vtype:comment"} = 1;
    } elsif (/^(\w+)\t\t\t# ([\x{2605}\x{2606}])$/) {
      $Data->{variants}->{$1}->{"cjkvi:$2$1"}->{$vtype} = 1;
    } elsif (/\S/) {
      warn join " ", map { sprintf "%04X", ord $_ } split //, $_;
      die "Bad line |$_|";
    }
  }
}

for (
  ['duplicate-chars.txt'],
  ['non-cjk.txt'],
  ['non-cognates.txt'],
  ['ucs-scs.txt'],
  ['jisx0212-variants.txt'],
  ['jisx0213-variants.txt'],
  ['x0212-x0213-variants.txt'],
  ['joyo-variants.txt'],
  ['jinmei-variants.txt'],
  ['hyogai-variants.txt'],
  ['jp-borrowed.txt'],
  ['dypytz-variants.txt'],
  ['hydzd-borrowed.txt'],
  ['hydzd-variants.txt'],
  ['koseki-variants.txt'],
  ['twedu-variants.txt'],
  ['sawndip-variants.txt'],
  ['numeric-variants.txt'],
  ['radical-variants.txt'],
  ['cjkvi-variants.txt'],
  ['cjkvi-simplified.txt'],
) {
  my ($fname) = @$_;
  my $path = $TempPath->child ('repo', $fname);
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^#/) {
      #
    } elsif (m{^([^,\s]+),([a-z0-9/-]+),([^,\s]+)\s*$}) {
      my $c1 = wrap $1;
      my $c2 = wrap $3;
      next if $c2 eq "\x{FFFD}";
      my $vtype = "cjkvi:$2";
      $Data->{variants}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (m{^([^,\s]+),(hydcd/borrowed),([^,\s]+),[0-9]+$}) {
      my $c1 = wrap $1;
      my $c2 = wrap $3;
      next if $c2 eq "\x{FFFD}";
      my $vtype = "cjkvi:$2";
      $Data->{variants}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (m{^([^,\s]+),([a-z0-9/]+),([^,\s]+)[, ]\[}) {
      my $c1 = wrap $1;
      my $c2 = wrap $3;
      next if $c2 eq "\x{FFFD}";
      my $vtype = "cjkvi:$2";
      $Data->{variants}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (m{^([^,\s]+),([a-z0-9/-]+),([^,\s]+),([^,\s]+|JIS X 0213:2004)\s*$}) {
      my $c1 = wrap $1;
      my $c2 = wrap $3;
      next if $c2 eq "\x{FFFD}";
      my $vtype = "cjkvi:$2:$4";
      $vtype =~ s/ /-/g;
      $Data->{variants}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (/^[a-z]/) {
      #
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
