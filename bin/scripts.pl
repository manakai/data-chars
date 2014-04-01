use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib');
use Encode;
use JSON::Functions::XS qw(perl2json_bytes_for_record file2perl);

my $Data = {};

{
  my $langtags = file2perl file (__FILE__)->dir->parent->file ('local', 'langtags.json');
  for (keys %{$langtags->{script}}) {
    my $data = $langtags->{script}->{$_};
    my $code = ucfirst $_;
    if (@{$data->{Description} or []}) {
      if (@{$data->{Description}} == 1 and
          $data->{Description}->[0] eq 'Private use') {
        $Data->{scripts}->{$code}->{private} = 1;
      } else {
        $Data->{scripts}->{$code}->{desc} = $data->{Description};
      }
    }
    $Data->{scripts}->{$code}->{iso} = $code;
    $Data->{scripts}->{$code}->{ianareg} = $data->{_added}
        if defined $data->{_added} and $data->{_registry}->{iana};
    $Data->{scripts}->{$code}->{iana_comments} = $data->{Comments}
        if $data->{Comments};
  }

  for (keys %{$langtags->{u_nu}}) {
    my $code = $_;
    my $data = $langtags->{u_nu}->{$_};
    $code = ucfirst $code if 4 == length $code;
    $Data->{scripts}->{$code}->{u_nu_desc} = $data->{Description}->[0]
        if @{$data->{Description} or []};
    $Data->{scripts}->{$code}->{u_nu} = $_;
  }
}

my %unicode;
for my $scripts_f (
  file (__FILE__)->dir->parent->file ('local', 'ucd', 'PropertyValueAliases.txt'),
) {
  for (($scripts_f->slurp)) {
    if (/^sc\s+;\s+(\S+)\s+;\s+(\S+)\s+;\s+(\S+)/) {
      $Data->{scripts}->{$1}->{unicode} = $2;
      $Data->{scripts}->{$3}->{preferred} = $1;
      $Data->{scripts}->{$3}->{unicode} = $2;
      $unicode{$2}++;
    } elsif (/^sc\s+;\s+(\S+)\s+;\s+(\S+)/) {
      $Data->{scripts}->{$1}->{unicode} = $2;
      $unicode{$2}++;
    }
  }
}

for my $scripts_f (
  file (__FILE__)->dir->parent->file ('local', 'ucd', 'Scripts.txt'),
) {
  my %unicode_found;
  for (($scripts_f->slurp)) {
    if (/^([0-9A-Fa-f]+)\.\.([0-9A-Fa-f]+)\s+;\s+([^#]+)/) {
      $unicode_found{$_}++ for split /\s+/, $3;
    } elsif (/^([0-9A-Fa-f]+)\s+;\s+([^#]+)/) {
      $unicode_found{$_}++ for split /\s+/, $2;
    }
  }

  for (keys %unicode_found) {
    $Data->{_errors}->{'script_' . $_} = 'ISO code not found' unless $unicode{$_};
  }
}

{
  my $json = file2perl file (__FILE__)->dir->parent->file ('local', 'tr31.json');
  for my $key (qw(excluded recommended aspirational limited)) {
    for (keys %{$json->{scripts}->{$key}}) {
      $Data->{scripts}->{$_}->{unicode_id} = $key;
    }
  }
}

## <http://www.w3.org/TR/xforms/#mode-scripts>
for (keys %{$Data->{scripts}}) {
  my $u = $Data->{scripts}->{$_}->{unicode} // next;
  next if $u eq 'Common' or $u eq 'Unknown';
  my $f = $u;
  $f =~ tr/_//d;
  $Data->{scripts}->{$_}->{xforms} = $f;
}
$Data->{scripts}->{Hans}->{xforms} = 'simplifiedHanzi';
$Data->{scripts}->{Hant}->{xforms} = 'traditionalHanzi';
$Data->{scripts}->{Zmth}->{xforms} = 'math';

$Data->{scripts}->{$_}->{xforms} = $_
    for qw(ipa hanja kanji user);

## <http://www.unicode.org/reports/tr35/tr35-collation.html#Script_Reordering>
$Data->{scripts}->{$_}->{collation_reorder} = $_
    for qw(space punct symbol currency digit);
$Data->{scripts}->{Zzzz}->{collation_reorder} = 'others';
for (keys %{$Data->{scripts}}) {
  if (($Data->{scripts}->{$_}->{unicode_id} // '') eq 'recommended') {
    $Data->{scripts}->{$_}->{collation_reorder} = $_
        unless $_ eq 'Kana' or # Katakana
               $_ eq 'Zyyy' or # Common
               $_ eq 'Zinh'; # Inherited
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
