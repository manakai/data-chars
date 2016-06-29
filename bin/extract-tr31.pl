use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib');
use Encode;
use JSON::Functions::XS qw(perl2json_bytes_for_record file2perl);
use Web::DOM::Document;
use Web::HTML::Parser;

my $Data = {};

{
  my $html_f = file (__FILE__)->dir->parent->file ('local', 'tr31.html');
  my $doc = new Web::DOM::Document;
  my $parser = new Web::HTML::Parser;
  $parser->parse_byte_string ('utf-8', (scalar $html_f->slurp) => $doc);
  my $last_name = '';
  my $tables = {};
  for my $el ($doc->all->to_list) {
    my $name = $el->get_attribute ('name') // '';
    $last_name = $name if length $name;
    if ($el->local_name eq 'table') {
      $tables->{$last_name} ||= $el;
    }
  }

  for my $def (
    [inclusion_start => 'Table_Optional_Start'],
    [inclusion_medial => 'Table_Optional_Medial'],
    [inclusion_continue => 'Table_Optional_Continue'],
  ) {
    my $tbl = $tables->{$def->[1]};
    if (defined $tbl) {
      for my $tr ($tbl->rows->to_list) {
        my $cp = $tr->cells->[0] or next;
        next unless $cp->local_name eq 'td';
        my $tc = $cp->text_content;
        $tc =~ s/^\s+//;
        $tc =~ s/\s+$//;
        if ($tc =~ /^([0-9A-Fa-f]+)$/) {
          $Data->{chars}->{'candidates_for_'.$def->[0]}->{hex $1} = 1;
        } elsif ($tc =~ /\S/) {
          warn $tc;
        }
      }
    }
    die "no candidates for $def->[0]" unless 0+keys %{$Data->{chars}->{'candidates_for_'.$def->[0]} or {}};
  } # $def
  ## Was: 'Table_Candidate_Characters_for_Inclusion_in_Identifiers'
  $Data->{chars}->{candidates_for_inclusion}->{$_} = 1
      for keys %{$Data->{chars}->{candidates_for_inclusion_start}};
  $Data->{chars}->{candidates_for_inclusion}->{$_} = 1
      for keys %{$Data->{chars}->{candidates_for_inclusion_medial}};
  $Data->{chars}->{candidates_for_inclusion}->{$_} = 1
      for keys %{$Data->{chars}->{candidates_for_inclusion_continue}};

  for my $def (
    ['Table_Candidate_Characters_for_Exclusion_from_Identifiers' => 'excluded'],
    ['Table_Recommended_Scripts' => 'recommended'],
    ['Aspirational_Use_Scripts' => 'aspirational'],
    ['Table_Limited_Use_Scripts' => 'limited'],
  ) {
    if (defined $tables->{$def->[0]}) {
      for my $tr ($tables->{$def->[0]}->rows->to_list) {
        if ($tr->cells->[0]->text_content =~ /^\s*\[:script=([A-Za-z]+):\]\s*$/) {
          $Data->{scripts}->{$def->[1]}->{$1} = 1;
        }
      }
    }
    die "no $def->[1]" unless keys %{$Data->{scripts}->{$def->[1]} or {}};
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.

