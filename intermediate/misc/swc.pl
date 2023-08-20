use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;
use Web::DOM::Document;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwm');

my $Data = {};

my $VKey = {};
{
  my $path = $TempPath->child ('swglyphs.json');
  my $json = json_bytes2perl $path->slurp;
  for my $item (@$json) {
    my $id = $item->{id}->[0]->{text} // '';
    next unless $id =~ /^swc[1-9][0-9]*$/;
    my $c1 = ':' . $id;
    my $key = $VKey->{$c1};
    for my $value (@{$item->{unified} or []}) {
      if ($value->{text} =~ /^(\w)/) {
        $key //= get_vkey $value->{text};
        $VKey->{$c1} //= $key;
      }
      my $c2 = $value->{text};
      unless (length $c2) {
        warn "Bad value: |$value->{xml}|";
        next;
      }
      $Data->{$key // 'chars'}->{$c1}->{$c2}->{'manakai:unified'} = 1;
    }
    for my $value (@{$item->{downgrade} or []}) {
      if ($value->{text} =~ /^(\w)/) {
        $key //= get_vkey $1;
        $VKey->{$c1} //= $key;
      }
      my $c2 = $value->{text};
      unless (length $c2) {
        warn "Bad value: |$value->{xml}|";
        next;
      }
      if (1 == length $c2) {
        $Data->{$key // 'chars'}->{$c1}->{$c2}->{'manakai:equivalent'} = 1;
      } else {
        $Data->{$key // 'chars'}->{$c1}->{$c2}->{'manakai:alt'} = 1;
      }
    }
  }
}

{
  my $path = $TempPath->child ('swchars.json');
  my $json = json_bytes2perl $path->slurp;
  use utf8;
  for my $item (@$json) {
    my $c1 = $item->{文字}->[0]->{text} // '';
    next unless length $c1;
    my $key = $VKey->{$c1} || get_vkey $c1;
    for (
      [略字 => 'manakai:variant:simplified'],
      [新字体 => 'manakai:variant:jpnewstyle'],
      [異体字 => 'manakai:equivalent'],
      [避諱 => 'manakai:taboo'],
      [欠画 => 'manakai:taboovariant'],
      [同訓異字 => 'manakai:doukun'],
      [代替表現 => 'manakai:alt'],
      [関連 => 'manakai:related'],
      [字形類似 => 'manakai:lookslike'],
    ) {
      my ($k, $rel_type) = @$_;
      for my $value (@{$item->{$k}}) {
        my $c2 = $value->{text};
        next unless length $c2;
        $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
      }
    }
  }
}

sub tc ($) {
  my $el = shift;

  for (@{$el->children}) {
    if ($_->local_name eq 'title') {
      return $_->text_content;
    }
  }

  return $el->text_content;
} # tc

{
  my $path = $TempPath->child ('swjinmeikana.json');
  my $json = json_bytes2perl $path->slurp;
  my $doc = new Web::DOM::Document;
  my $el = $doc->create_element ('div');
  for (@{$json}) {
    for my $item (@{$_->{items}}) {
      $el->text_content ('');
      eval { $el->inner_html ($item->{xml}) };

      my @ji = map { tc $_ } @{$el->query_selector_all ('[itemprop=ji]')};
      my @yomi = map { tc $_ } @{$el->query_selector_all ('[itemprop=yomi]')};
      for (@ji) {
        my $c1 = wrap_string $_;
        for (@yomi) {
          my $c2 = wrap_string $_;
          $Data->{kanas}->{$c1}->{$c2}->{'manakai:jinmeikana'} = 1;
        }
      }
    }
  }
}

write_rel_data_sets
    $Data => $ThisPath, 'swc',
    [];

## License: Public Domain.

