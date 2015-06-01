use strict;
use warnings;
use Encode;

local $/ = undef;
my $js = decode 'utf-8', scalar <>;
$js =~ s{^\s*//.*$}{}gm;
$js =~ s{^\s*/\*.*?\*/}{}mgs;

die unless $js =~ m{\bpref\s*\(\s*"network.IDN.blacklist_chars"\s*,\s*"([^"]+)"\s*\)\s*;};

my $chars = $1;

print qq{
#label:Gecko network.IDN.blacklist_chars
#sw:network.IDN.blacklist_chars
#url:http://kb.mozillazine.org/Network.IDN.blacklist_chars
[$chars]
};

## License: Public Domain.
