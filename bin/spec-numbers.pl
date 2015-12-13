use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Web::DOM::Document;
use JSON::PS;

my $Data = {};

my $input_path = path (__FILE__)->parent->parent->child ('local/spec-numbers.html');

my $doc = new Web::DOM::Document;
$doc->manakai_is_html (1);
$doc->manakai_set_url (q<https://manakai.github.io/spec-numbers/>);
$doc->inner_html ($input_path->slurp_utf8);

for my $item (@{$doc->query_selector_all ('[itemtype=cjk-numeral]')}) {
  my $data = {};
  my $props = $item->manakai_get_properties;
  for my $prop (keys %$props) {
    $data->{$prop} = [map {
      if ($prop eq 'category' and $_->local_name eq 'a') {
        $Data->{categories}->{$_->text_content}->{url} = $_->href;
      }
      $_->text_content;
    } @{$props->{$prop}}];
  }
  push @{$Data->{'cjk-numeral'} ||= []}, $data;
}

print perl2json_bytes $Data;

## License: Public Domain.
