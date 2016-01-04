use strict;
use warnings;
use Path::Tiny;

my $category_name = shift or die;
my $unicode_version = shift or die;

my $root_path = path (__FILE__)->parent->parent;
my $src_path = $root_path->child ('src/set', $category_name);
my $dest_path = $root_path->child ('src/set', $category_name . '-' . $unicode_version);

$src_path->visit (sub {
  my $src_file_path = $_[0];
  return unless $src_file_path =~ qr/\.expr$/;
  my $rel = $src_file_path->relative ($src_path);
  return if $src_file_path =~ m{rfc5892/Unstable.expr$} or
            $src_file_path =~ m{rfc7564/HasCompat.expr$};
  my $dest_file_path = $dest_path->child ($rel);
  my $data = $src_file_path->slurp;

  $data =~ s/\$rfc5892:/\$rfc5892-$unicode_version:/g;
  $data =~ s/\$rfc7564:/\$rfc7564-$unicode_version:/g;
  my $uv = $unicode_version;
  $uv =~ s/\.0$//;
  $data =~ s/\$unicode:/\$unicode$uv:/g;

  $dest_file_path->parent->mkpath;
  $dest_file_path->spew ($data);
}, {recurse => 1});

## License: Public Domain.
