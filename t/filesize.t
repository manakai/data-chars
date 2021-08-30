use strict;
use warnings;

my $has_error = 0;

for my $file_name (map { glob $_ }
                       "data/*",
                       "data/*/*",
                       "view/*/*",
                       "intermediate/*/*") {
  my $size = -s $file_name;
  if ($size > 50*1000*1000) {
    printf "# ERROR: %s (%dMB) %s\x0A",
        $size,
        $size/1024/1024,
        $file_name;
    $has_error = 1;
  } elsif ($size > 1*1000*1000) {
    printf "# Warning: %s (%dMB) %s\x0A",
        $size,
        $size/1024/1024,
        $file_name;
  }
}

print "1..1\n";
print $has_error ? "not ok 1\n" : "ok 1\n";
exit $has_error;

## License: Public Domain.
