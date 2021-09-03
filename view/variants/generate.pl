use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $DataPath = $RootPath->child ('intermediate/variants');
my $WithRels = $ENV{WITH_RELS};

my $Data;
{
  my $path = $DataPath->child ('cluster-root.json');
  $Data = json_bytes2perl $path->slurp;
}
my $DataChars = [];
{
  my $i = 0;
  {
    $i++;
    my $path = $DataPath->child ("cluster-chars-$i.txt");
    last unless $path->is_file;
    my $file = $path->openr;
    local $/ = "\x0A\x0A";
    while (<$file>) {
      push @$DataChars, json_bytes2perl $_;
    }
    redo;
  }
}
my $DataProps = [];
{
  my $i = 0;
  {
    $i++;
    my $path = $DataPath->child ("cluster-props-$i.txt");
    last unless $path->is_file;
    my $file = $path->openr;
    local $/ = "\x0A\x0A";
    while (<$file>) {
      push @$DataProps, json_bytes2perl $_;
    }
    redo;
  }
}
my $DataRels;
if ($WithRels) {
  $DataRels = [];
  my $i = 0;
  {
    $i++;
    my $path = $DataPath->child ("cluster-rels-$i.jsonl");
    last unless $path->is_file;
    my $file = $path->openr;
    local $/ = "\x0A";
    while (<$file>) {
      push @$DataRels, json_bytes2perl $_;
    }
    redo;
  }
}

sub v_char ($$) {
  my ($c, $stems) = @_;
  return sprintf q{<v-char class="%s %s %s %s %s" data-stem="%s"><data>%s</data><code>%s</code></v-char>},
      ($stems->{jp}->{$c} ? 'stem-jp' : ''),
      ($stems->{jp2}->{$c} ? 'stem-jp2' : ''),
      ($stems->{cn}->{$c} ? 'stem-cn' : ''),
      ($stems->{hk}->{$c} ? 'stem-hk' : ''),
      ($stems->{tw}->{$c} ? 'stem-tw' : ''),
      (join '', map {
        {
          all => '',
          jp => 'J',
          jp2 => 'j',
          cn => 'C',
          hk => 'H',
          tw => 'T',
        }->{$_} // $_;
      } sort { $a cmp $b } grep { $stems->{$_}->{$c} } keys %{$stems}),
      $c,
      join ' ', map { sprintf 'U+%04X', ord $_ } split //, $c;
} # v_char

binmode STDOUT, qw(:encoding(utf-8));
print q{
  <!DOCTYPE HTML>
  <meta charset=utf-8>
  <title>Han variants</title>
  <style>
    html {
      line-height: 1;
    }
    section {
      margin-top: .5em;
      border-top: solid 1px gray;
      padding-top: .5em;
      margin-left: .5em;
      border-left: solid .5em gray;
      padding-left: .5em;
      margin-bottom: .5em;
      border-bottom: solid 1px gray;
      padding-bottom: .5em;
    }
    section.compact:not(.no-compact-ancestor) {
      display: inline-block;
      margin: 1px;
      border: 1px solid gray;
      padding: 1px;
    }
    section.compact.single-cluster:not(.no-compact-ancestor),
    section.single-char {
      display: contents;
    }
    header {
      margin-bottom: .5em;
    }
    section.compact > header {
      display: none;
    }
    h1 {
      display: inline;
      margin: 0 1em 0 0;
      font-size: 100%;
    }

    h1 > v-char {
      vertical-align: middle;
    }
  
    header p {
      display: inline;
    }

    .leaders {
      display: inline-block;
      margin: 0 .5rem;
      padding: 0;
      vertical-align: middle;
      font-size: 70%;
    }
    .leaders::before {
      content: "(";
    }
    .leaders::after {
      content: ")";
    }
    .leaders::before, .leaders::after {
      font-weight: normal;
      vertical-align: -1em;
    }
    .leaders > div {
      display: inline-block;
      vertical-align: top;
      min-width: 3em;
    }
    .leaders dt,
    .leaders dd {
      display: block;
      margin: 0;
      padding: 0;
      text-align: center;
    }
    .leaders dt {
      font-weight: bolder;
      font-size: 80%;
    }
    .leaders dd {
      font-weight: normal;
    }

    p {
      margin: 0;
    }
    p + p {
      margin-top: 1em;
    }
    v-char {
      display: inline-block;
      text-align: center;
      width: min-content;
      vertical-align: top;
    }
    v-char[data-stem]:not([data-stem=""])::after {
      content: attr(data-stem);
      display: block;
      font-size: 80%;
      font-weight: normal;
    }
    v-char data {
      display: block;
      font-size: 200%;
    }
    v-char code {
      font-weight: normal;
    }
    v-n {
      display: inline-block;
      font-size: 200%;
    }
    .stem-jp,
    .stem-jp2,
    .stem-cn,
    .stem-hk,
    .stem-tw {
      background: #ffdddd;
      color: black;
    }

    .rels {
      font-size: 80%;
    }
    section.compact > .rels {
      display: none;
    }
    .rels li {
      display: block;
      margin: 0;
      padding: 0;
    }
    .rels v-char::after { display: none ! important }
    .rels v-char data {
      font-size: 100%;
    }
    .rels v-char code {
      font-size: 80%;
    }

    #status:empty { display: none }
    #status {
      margin: .5em;
      padding: .5em;
      font-size: 200%;
      background: red;
      color: white;
    }
  </style>
  <script>
    ondblclick = ev => {
      var e = ev.target;
      while (e && !e.classList.contains ('compact')) {
        e = e.parentNode;
      }
      if (e) {
        e.classList.remove ('compact');
      }
    };
  </script>

  <div id=status></div>

  <script>
    function load (fileNames) {
      var p = document.currentScript;
      var status = document.createElement ('p');
      document.querySelector ('#status').appendChild (status);
      status.textContent = 'Loading ' + fileNames + '...';

      return Promise.all (fileNames.map (_ => fetch (_).then (res => {
        if (res.status !== 200) throw res;
        return res.text ();
      }))).then (texts => {
        p.outerHTML = texts.join ('');
        status.remove ();
      });
    }
  </script>

  <p>[<a href=list.html>Clusters</a>
  <a href=list-rels.html>with relations</a>]
  </p>
};

printf q{<p>Clusters: %s},
    join ' in ', reverse @{$Data->{stats}->{clusters}};

my $LeaderTypes = [sort { $a->{index} <=> $b->{index} } values %{$Data->{leader_types}}];
sub sprint_cluster ($$$;%);
sub sprint_cluster ($$$;%) {
  my ($cluster_index, $level_index, $id_prefix, %args) = @_;
  my $cluster = $DataChars->[$cluster_index];
  my $props = $DataProps->[$cluster_index];
  my $level = $Data->{cluster_levels}->[$level_index];
  my $r = '';

  my $compact = (10 > keys %{$cluster->{chars}} and 1 < keys %{$cluster->{chars}});
  $compact = 1 if 1 == @{$cluster->{cluster_indexes} or []};
  if ($compact and not $args{has_non_compact} and
      1 < @{$cluster->{cluster_indexes} or []}) {
    $compact = 0;
  }
  $compact = 0 if not $args{has_non_compact} and not defined $cluster->{cluster_indexes};
  
  my $id = $id_prefix . '-' . $props->{leaders}->{all};
  $r .= sprintf q{<section id="%s" class="%s %s %s %s %s">},
      $id,
      (defined $cluster->{cluster_indexes} ? '' : 'leaf'),
      (1 == @{$cluster->{cluster_indexes} or []} ? 'single-cluster' : ''),
      (1 == keys %{$cluster->{chars}} ? 'single-char' : ''),
      ($compact ? 'compact' : ''),
      (!$args{has_non_compact} ? 'no-compact-ancestor' : '');

  $args{has_non_compact} = 1 unless $compact;
  
  if (@{$cluster->{cluster_indexes} or []}) {
    if (@{$cluster->{cluster_indexes}} > 1 or
        1 < keys %{$cluster->{chars}}) {
      $r .= sprintf qq{<header><h1>%s %s</h1>\x0A},
          (v_char $props->{leaders}->{all}, $props->{stems}),
          $level->{label};

      $r .= sprintf q{<dl class=leaders>};
      for my $lt (@$LeaderTypes) {
        $r .= sprintf q{<div><dt>%s<dd lang="%s">},
            $lt->{short_label},
            $lt->{lang_tag};
        my $c = $props->{leaders}->{$lt->{key}};
        if (defined $c) {
          $r .= v_char $c, $props->{stems};
        } else {
          $r .= q{<v-n>-</v-n>};
        }
        $r .= qq{</div>\x0A};
      }
      $r .= q{</dl>};

      $r .= sprintf qq{<p>%d clusters, <a href="#%s-rels">%d relations</a>, %d characters</header>\x0A},
          0+@{$cluster->{cluster_indexes}},
          $id,
          $cluster->{rel_count},
          0+keys %{$cluster->{chars}};
    }
    
    for (@{$cluster->{cluster_indexes}}) {
      $r .= sprint_cluster $_, $level_index - 1, $id,
          has_non_compact => $args{has_non_compact};
    }
  } else { # leaf cluster
    if (0 and
        1 < keys %{$cluster->{chars}}) {
      $r .= q{<p><strong>};
      $r .= v_char $props->{leaders}->{all}, $props->{stems};
      $r .= sprintf qq{</strong> (%d): \n}, 0+keys %{$cluster->{chars}};
    }
    
    for my $c (sort { $a cmp $b } keys %{$cluster->{chars}}) {
      $r .= v_char $c, $props->{stems};
      $r .= "\x0A";
    }
  }

  if ($WithRels and
      1 < keys %{$cluster->{chars}}) {
    $r .= sprintf q{<ul class=rels id="%s-rels">}, $id;
    for my $rel (@{$DataRels->[$cluster->{index}]}) {
      $r .= sprintf qq{<li>%s \x{2192} %s [%d/%d] %s\n},
          (v_char $rel->[0], $props->{stems}),
          (v_char $rel->[1], $props->{stems}),
          $rel->[2],
          $rel->[3],
          join ', ', @{$rel->[4]};
    }
    $r .= q{</ul>};
  }
  
  $r .= qq{</section>\n};
  return $r;
} # sprint_cluster

{
  my $results = [];
  my $i = 0;
  my $n = 0;
  my $cont = 0;
  for (@{$Data->{cluster_indexes}}) {
    my $v = sprint_cluster $_, $#{$Data->{cluster_levels}}, 'cluster',
        has_non_compact => 0;
    if (not $cont) {
      $i++;
      my $name = $WithRels ? "list-rels-html-$i" : "list-html-$i";
      push @$results, [$name, ''];
      $cont = 1;
    }

    $results->[-1]->[1] .= $v;

    my $cluster = $DataChars->[$_];
    $n += keys %{$cluster->{chars}};
    if ($n > 10000) {
      $cont = 0;
      $n = 0;
    }
  } # $_

  my $chunk_length = 10_000_000;
  for my $r (@$results) {
    my $j = 0;

    my $names = [];
    while (length $r->[1]) {
      my $name = "$r->[0]-$j.txt";
      my $path = $ThisPath->child ($name);
      push @$names, $name;
      my $file = $path->openw;

      print $file encode_web_utf8 substr $r->[1], 0, $chunk_length;
      substr ($r->[1], 0, $chunk_length) = '';
      $j++;
    }
    printf qq{<script>load ([%s])</script>\n},
        join ', ', map { qq{"$_"} } @$names;
  } # $r
}

## License: Public Domain.
