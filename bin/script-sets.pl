use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->child ('modules/*/lib')->stringify;
use Charinfo::Set;
use JSON::PS;

my $unicode_version = shift or die;

my $root_path = path (__FILE__)->parent->parent;
my $input_ucd_path = $root_path->child ('local/unicode', $unicode_version);
my $uv = ($unicode_version eq 'latest' ? '' : $unicode_version);
$uv =~ s/\.0$//;
my $output_src_path = $root_path->child ('src/set/unicode' . $uv);

my $ToValue = {};
my $ScriptNames = {};

my $scripts_path = $root_path->child ('data/scripts.json');
my $scripts = json_bytes2perl $scripts_path->slurp;
my $ToCanonScript = {};
for my $data (values %{$scripts->{scripts}}) {
  for (keys %{$data->{unicode_names} or {}}) {
    $ToCanonScript->{$_} = $data->{unicode};
  }
}

my $input_path = $input_ucd_path->child ('Scripts.txt');
for (split /\x0D?\x0A/, $input_path->slurp) {
  if (/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s*;\s*([A-Za-z0-9_\s-]+)/) {
    my $from = hex $1;
    my $to = defined $2 ? hex $2 : $from;
    my $type = $3;
    $type =~ s/\A\s+//;
    $type =~ s/\s+\z//;
    $type =~ s/\s+/_/g;
    $type = $ToCanonScript->{$type} or die $type;
    for ($from..$to) {
      $ToValue->{$_} = $type;
    }
    $ScriptNames->{$type} = 1;
  }
}

my $data_path = $output_src_path->child ('Script');
$data_path->mkpath;

sub hdr ($$) {
  return sprintf q{#label:Unicode %s=%s
#sw:%s
}, $_[0], $_[1],
    $_[1];
} # hdr

for my $script_name (sort { $a cmp $b } keys %$ScriptNames) {
  my $path = $data_path->child ("$script_name.expr");
  print STDERR "\rScript |$path|... ";
  my $set = [];
  push @$set, [$_, $_] for sort { $a <=> $b } grep { $ToValue->{$_} eq $script_name } keys %$ToValue;
  $path->spew_utf8
      (hdr ('Script', $script_name) . Charinfo::Set->serialize_set (Charinfo::Set::set_merge $set, []));
}

{
  my $path = $data_path->child ('Unknown.expr');
  $path->spew_utf8
      (hdr ('Script', 'Unknown') . '[\u0000-\u{10FFFF}]'
       . join '', map { "\x0A- " . '$unicode'.$uv.':Script:' . $_ } sort { $a cmp $b } keys %$ScriptNames);
}

for my $def (values %{$scripts->{scripts}}) {
  for my $name (keys %{$def->{unicode_names} or {}}) {
    unless ($name eq $def->{unicode}) {
      print { $data_path->child ($name . '.expr')->openw }
          '$unicode:Script:' . $def->{unicode};
    }
  }
}

{
  my $input_path = $input_ucd_path->child ('ScriptExtensions.txt');
  for (split /\x0D?\x0A/, $input_path->slurp) {
    if (/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s*;\s*([A-Za-z0-9_\s-]+)/) {
      my $from = hex $1;
      my $to = defined $2 ? hex $2 : $from;
      my $type = $3;
      $type =~ s/\A\s+//;
      $type =~ s/\s+\z//;
      $type =~ s/\s+/ /g;
      my @type = split / /, $type;
      @type = map {
        $ToCanonScript->{$_} or die $_;
      } @type;
      for ($from..$to) {
        $ToValue->{$_} = \@type;
      }
      $ScriptNames->{$_} = 1 for @type;
    }
  }
}

{
  my $data_path = $output_src_path->child ('Script_Extensions');
  $data_path->mkpath;
  
  for my $script_name (sort { $a cmp $b } keys %$ScriptNames) {
    my $path = $data_path->child ("$script_name.expr");
    print STDERR "\rScript_Extensions |$path|... ";
    my $set = [];
    push @$set, [$_, $_] for sort { $a <=> $b } grep {
      $ToValue->{$_} eq $script_name or
      (ref $ToValue->{$_} eq 'ARRAY' and
       grep { $_ eq $script_name } @{$ToValue->{$_}})
    } keys %$ToValue;
    $path->spew_utf8
        (hdr ('Script_Extensions', $script_name) . Charinfo::Set->serialize_set (Charinfo::Set::set_merge $set, []));
  }

  {
    my $path = $data_path->child ('Unknown.expr');
    $path->spew_utf8
        (hdr ('Script_Extensions', 'Unknown') . '[\u0000-\u{10FFFF}]'
         . join '', map { "\x0A- " . '$unicode'.$uv.':Script_Extensions:' . $_ } sort { $a cmp $b } keys %$ScriptNames);
  }
}

print STDERR "\rDone. \n";

## License: Public Domain.
