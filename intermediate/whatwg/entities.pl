use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;
BEGIN { require 'chars.pl' }
use Web::DOM::Document;
use Web::XML::Parser;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwh');

my $Data = {};
{
  my $path = $TempPath->child ('unicode.xml');
  my $doc = Web::DOM::Document->new;
  my $parser = Web::XML::Parser->new;
  $parser->parse_byte_string ('utf-8', $path->slurp, $doc);
  for my $c_el (@{$doc->query_selector_all ('character')}) {
    my $c1 = wrap_string join '', map { chr $_ } split /-/, $c_el->get_attribute ('dec');
    my $vkey = get_vkey $c1;
    for my $el (@{$c_el->children}) {
      my $ln = $el->local_name;
      if ($ln eq 'afii') {
        my $c2 = sprintf ':afii%d', hex $el->text_content;
        $Data->{$vkey}->{$c1}->{$c2}->{'xml-entities:afii'} = 1;
      } elsif ($ln eq 'latex' or $ln eq 'mathlatex' or $ln eq 'AMS' or
               $ln eq 'IEEE' or $ln eq 'APS' or $ln eq 'AIP' or
               $ln eq 'Wolfram') {
        my $c2 = wrap_string $el->text_content;
        $Data->{descs}->{$c1}->{$c2}->{'xml-entities:' . $ln} = 1
            unless $c1 eq $c2;
      } elsif ($ln eq 'entity') {
        my $c2 = wrap_string $el->get_attribute ('id');
        $Data->{descs}->{$c1}->{$c2}->{'xml-entities:entity'} = 1
            unless $c1 eq $c2;
      } elsif ($ln eq 'combref' or $ln eq 'noncombref') {
        $el->get_attribute ('ref') =~ /^U([0-9A-F]+)$/ or die $el->outer_html;
        my $c2 = u_chr hex $1;
        my $rel_type = 'xml-entities:' . $ln . ':' . $el->get_attribute ('style');
        $Data->{$vkey}->{$c1}->{$c2}->{$rel_type} = 1;
      } elsif ($ln eq 'Elsevier') {
        my $c2 = wrap_string $el->get_attribute ('ent');
        if (length $c2) {
          $Data->{descs}->{$c1}->{$c2}->{'xml-entities:Elsevier'} = 1
              unless $c1 eq $c2;
        }
      } elsif ($ln eq 'surrogate') {
        $el->get_attribute ('ref') =~ /^U([0-9A-F]+)$/ or die $el->outer_html;
        my $c2 = u_chr hex $1;
        my $rel_type = 'xml-entities:mathvariant:' . $el->get_attribute ('mathvariant');
        $Data->{$vkey}->{$c1}->{$c2}->{$rel_type} = 1;
      }
      if (length $c1) {
        my @c = split_char $c1;
        if (@c > 1) {
          for my $c2 (@c) {
            $Data->{components}->{$c1}->{$c2}->{'string:contains'} = 1;
          }
        }
      }
    }
  }
}

{
  my $path = $TempPath->child ('html-charrefs.json');
  my $json = json_bytes2perl $path->slurp;
  for my $ent (keys %$json) {
    my $n = $ent;
    my $x = '';
    $x .= '&' if $n =~ s/^&//;
    $x .= ';' if $n =~ s/;$//;
    my $ref_type = 'html:' . $x;
    my $c2 = wrap_string $json->{$ent}->{characters};
    my $c1 = wrap_string $n;
    $Data->{descs}->{$c1}->{$c2}->{$ref_type} = 1;
  }
}

write_rel_data_sets
    $Data => $ThisPath, 'entities',
    [
    ];

## License: Public Domain.

