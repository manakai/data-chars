use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;
use Encode;
use Charinfo::Set;
use Web::DOM::Document;
use Web::XML::Parser;

my $version = shift or die;

my $Sets = {};

my $input_f = file (__FILE__)->dir->parent->file ('local', 'iana-precis', "$version.xml");
my $doc = new Web::DOM::Document;
my $parser = new Web::XML::Parser;
$parser->parse_char_string ((decode 'utf-8', scalar $input_f->slurp) => $doc);

my $data_d = file (__FILE__)->dir->parent->subdir ('src', 'set', 'precis-tables-' . $version);
$data_d->mkpath;

if ($doc->document_element->local_name eq 'redirect') {
  my $reg = $doc->document_element->get_attribute ('registry')
      or die "No redirect[registry]";
  for (qw(PVALID CONTEXT CONTEXTJ CONTEXTO UNASSIGNED DISALLOWED
          ID_DIS FREE_PVAL ID_PVAL FREE_DIS)) {
    my $f = $data_d->file ($_ . '.expr');
    print { $f->openw } sprintf '$%s:%s', $reg, $_;
  }
  chdir file (__FILE__)->dir->parent->stringify;
  $reg =~ s/^precis-tables-//;
  exec 'make', "src/set/precis-tables-$reg/files", 'UNICODE_VERSION=' . $reg;
}

for (qw(PVALID CONTEXT CONTEXTJ CONTEXTO UNASSIGNED DISALLOWED
        ID_DIS FREE_PVAL ID_PVAL FREE_DIS)) {
  $Sets->{$_} ||= [];
}

for (@{($doc->get_element_by_id ('precis-tables-properties') ||
        $doc->get_element_by_id ('precis-tables-'.$version.'-properties') ||
        $doc->document_element)
           ->get_elements_by_tag_name ('record')}) {
  my $from;
  my $to;
  my $type;
  my $type2;
  for (@{$_->children}) {
    if ($_->local_name eq 'codepoint') {
      my $cp = $_->text_content;
      if ($cp =~ /^([0-9A-F]+)-([0-9A-F]+)$/) {
        $from = hex $1;
        $to = hex $2;
      } elsif ($cp =~ /^([0-9A-F]+)$/) {
        $from = $to = hex $1;
      }
    } elsif ($_->local_name eq 'property') {
      if ($_->text_content =~ /^([A-Z]+)$/) {
        $type = $1;
      } elsif ($_->text_content =~ /^([A-Z_]+)\s+or\s+([A-Z_]+)$/) {
        $type = $1;
        $type2 = $2;
      }
    }
  }
  warn "Bad data", next unless defined $from and defined $to and defined $type;
  push @{$Sets->{$type} ||= []}, [$from => $to];
  push @{$Sets->{$type2} ||= []}, [$from => $to] if defined $type2;
}

for my $name (keys %$Sets) {
  my $f = $data_d->file ("$name.expr");
  print { $f->openw } Charinfo::Set->serialize_set (Charinfo::Set::set_merge $Sets->{$name}, []);
}

unless ($Sets->{CONTEXT}) {
  my $f = $data_d->file ('CONTEXT.expr');
  print { $f->openw } sprintf '$precis-tables-%s:CONTEXTJ | $precis-tables-%s:CONTEXTO', $version, $version;
}

## License: Public Domain.
