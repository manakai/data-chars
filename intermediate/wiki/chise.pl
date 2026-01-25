use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwm');

my $Data = {};
my $Types = {};

my $Rev = substr ((shift or die), 0, 7);

my $AdditionalIds = {
  'ascii' => ':ascii-%x',
  'katakana-jisx0201' => ':jisx0201-%x',
  'latin-jisx0201' => ':jisx0201-%x',
  'control-1' => ':ascii-%x',
  'latin-iso8859-1' => ':isolatin1-%Lx',
  'latin-iso8859-2' => ':isolatin2-%Lx',
  'latin-iso8859-3' => ':isolatin3-%Lx',
  'latin-iso8859-4' => ':isolatin4-%Lx',
  'greek-iso8859-7' => ':isogreek-%Lx',
  'arabic-iso8859-6' => ':isoarabic-%Lx',
  'hebrew-iso8859-8' => ':isohebrew-%Lx',
  'cyrillic-iso8859-5' => ':isocyrillic-%Lx',
  'latin-iso8859-9' => ':isolatin5-%Lx',
  'thai-tis620' => ':tis-%Lx',
  'ucs' => ':u%x',
  'latin-tcvn5712' => ':vscii-%x',
  #system-char-id
  'chinese-big5-1' => ':mulebig5-1-%x',
  'chinese-big5-2' => ':mulebig5-2-%x',
  #'chinese-big5-eten-a'
  #'chinese-big5-eten-b'
  'latin-viscii' => ':viscii-%x',
  'latin-viscii-lower' => ':muleviscii1-%Lx',
  'latin-viscii-upper' => ':muleviscii2-%Lx',
  'ethiopic' => ':muleethiopic-%d-%d',
  'ethiopic-ucs' => ':u%x',
  'ucs-smp' => ':u%x',
  'ucs-sip' => ':u%x',
  'sisheng' => ':omronzh-%x',
  'lao' => ':mulelao-%x',
  'ipa' => ':muleipa-%x',
  'arabic-digit' => ':mulearabic0-%Lx',
  'arabic-1-column' => ':mulearabic1-%Lx',
  'arabic-2-column' => ':mulearabic2-%Lx',
  'thai-xtis' => ':mulextis-%d-%d',
  'latin-iso8859-16' => ':isolatin10-%Lx',
  'latin-iso8859-14' => ':isolatin8-%Lx',
  'latin-iso8859-15' => ':isolatin9-%Lx',
};

sub serialize_id ($) {
  my $id = $_[0];
  
  my $name = $id->[0];
  if ($name eq 'name') {
    return "name-" . $id->[1];
  } elsif ($name eq '_our_name') {
    return $id->[1];
  }
  
  my $bad = 0;
  $name =~ s{^([=+>]+)}{
    {
      '==>' => 'a2.',
      '=>' => 'a.',
      '=' => 'rep.',
      '==' => 'g2.',
      '===' => 'repi.',
      '=+>' => 'o.',
      '=>>' => 'g.',
    }->{$1} // do {
      $bad = 1;
      '';
    };
  }e or defined $AdditionalIds->{$name} or return undef;
  return undef if $bad;
  $name =~ s{\*}{.-.}g;
  $name =~ s{/}{...}g;

  return undef if ref $id->[1];
  $name = $name . '=' . $id->[1];

  return $name;
} # serialize_id

my $NameMap = {};
sub serialize_string ($$);
sub serialize_string ($$) {
  my $ids = $_[0];
  my $operands = $_[1];
  my $s = '';
  for (@$ids[1..$#$ids]) {
    my $name;
    my $substring;
    for (@$_) {
      my $this_name = serialize_id $_;
      if (defined $this_name) {
        $name = $NameMap->{$this_name};
        last if defined $name;
      }

      if ($_->[0] eq 'ideographic-structure') { # nested IDS
        $substring = serialize_string $_, $operands; # or undef
      }
    }
    if (not defined $name and not defined $substring) {
      #use Data::Dumper;warn Dumper [$ids, $_];
      die "Not serializable string";
      return undef;
    }

    if (defined $substring) {
      $s .= $substring;
    } else {
      push @$operands, $name if is_not_ivs_char $name and not is_ids $name;
      $name =~ s/^:chise-//;
      if ($name =~ /^rep\.ucs=([0-9]+)$/) {
        my $x = u_chr $1;
        if ($x eq chr $1) {
          $s .= $x;
        } else {
          $s .= '{' . $name . '}';
        }
      } else {
        $s .= '{' . $name . '}';
      }
    }
  }

  return $s;
} # serialize_string

my $TempIndex = 0;

sub process_ids ($);
sub process_ids ($) {
  my $obj = $_[0];

  my $ids = [];
  my $rels = [];
  my $idses = [];
  my $name_f;
  my $c1;
  my @more;

  for my $f (@$obj) {
    if (($f->[0] =~ /^=/ or defined $AdditionalIds->{$f->[0]}) and
        not $f->[0] =~ /\*\w/) { # ID
      next if not defined $f->[1]; # no "...*notes" but "ucs*"
      my $type = "chise:$f->[0]";
      $Types->{$type} = 1;
      push @$ids, $f;
    } elsif ($f->[0] =~ /^<-|^->/ and not $f->[0] =~ /\*\w/) {
      my $type = "chise:$f->[0]";
      $Types->{$type} = 1;
      push @$rels, $f;
    } elsif ($f->[0] eq 'name') {
      $name_f = $f;
    } elsif ($f->[0] =~ /^(?:ideographic-structure|ideographic-combination)(?:$|\@)/ and not $f->[0] =~ /\*\w/) {
      my $type = "chise:$f->[0]";
      $Types->{$type} = 1;
      push @$idses, $f;
    } elsif ($f->[0] eq '_our_name') {
      $name_f = $f;
    }
  }

  ID: {
    ## <https://www.chise.org/specs/chise-format.pdf>

    my @name;
    for my $id (@$ids, ($name_f // ())) {
      my $name = serialize_id $id;
      next unless defined $name;

      if ($id->[0] eq '_our_name') {
        $c1 //= $id->[1];
      } elsif (defined $NameMap->{$name}) {
        $c1 = $NameMap->{$name};
        for (@name) {
          $NameMap->{$_} = $c1;
        }
      } else {
        $c1 //= ":chise-$name";
        $NameMap->{$name} = $c1;
        push @name, $name;
      }
    }
    if (not defined $c1) {
      ## No stable ID can be generated from the object.
    
      #use Data::Dumper;warn Dumper $obj;
      #warn "ID value not serializable";
      #return {};
      $c1 = ":chise---" . $Rev . '-' . $TempIndex++;
      push @$obj, ['_our_name', $c1];
    }

    my $key = 'rels';
    for my $id (@$ids) {
      my $raw_type = $id->[0];
      my $type = 'chise:'.$raw_type;
      if (defined $AdditionalIds->{$raw_type}) {
        #
      } else {
        $type =~ /^chise:[=+>]+(.*)$/ or die $type;
        $raw_type = $1;
      }
    
      my $pattern = {
        "big5" => ':b5-%x',
        "big5-cdp" => ':b5-cdp-%x',
        'big5-cdp@iwds-1' => ':b5-cdp-%x',
        'big5-cdp@cognate' => ':b5-cdp-%x',
        'big5-cdp@component' => ':b5-cdp-%x',
        "big5-eten" => ':b5-%x',
        "big5-pua" => ':b5-%x',
        cbeta => ':cbeta%d',
        "chise-hdic-ktb-seal" => ':chise-hdic-ktb-seal-%d',
        'chise-kangxi@kokusho-200014683' => ':chise-kangxi-%d',
        daikanwa => ':m%d',
        'daikanwa@rev1' => ':m%d',
        'daikanwa@rev2' => ':m%d',
        'daikanwa/+p' => ":m%d'",
        'daikanwa/+2p' => ":m%d''",
        'daikanwa/ho' => ':mh%d',
        daijiten => ':daijiten%d',
        #'daijiten*note' =>
        gt => ':gt%d',
        'gt-k' => ':gtk%d',
        "hanyo-denshi/ip" => ':IP%04X',
        "hanyo-denshi/jt" => ':JT%04X',
        "hanyo-denshi/ks" => ':KS%06d',
        "hanyo-denshi/tk" => ':TK%08d',
        #hdic-ktb-seal-glyph-id
        'iwds-1' => ':chise-iwds-1-%d',
        #iwds-1*level iwds-1*note
        'jef-china3' => ':chise-china3-%x',
        koseki => ':koseki%d',
        mj => ':MJ%06d',
        'ruimoku-v6' => ':u-rui6-%x',
        shinjigen => ':shinjigen%d',
        'shinjigen@1ed' => ':shinjigen%d',
        'shinjigen@1ed/24pr' => ':shinjigen%d',
        'shinjigen@rev' => ':shinjigen%d',
        'shinjigen/+p@rev' => ":shinjigen%d'",
        'shuowen-jiguge' => ':chise-shuowen-jiguge-%d',
        'shuowen-jiguge4' => ':chise-shuowen-jiguge-%d',
        'shuowen-jiguge5' => ':chise-shuowen-jiguge-%d',
        'shuowen-jiguge-A30' => ':chise-shuowen-jiguge-%d',
        'zinbun-oracle' => ':zinbunoracle%d',
        
        "cns11643-1" => ':cns1-%d-%d',
        "cns11643-2" => ':cns2-%d-%d',
        "cns11643-3" => ':cns3-%d-%d',
        "cns11643-4" => ':cns4-%d-%d',
        "cns11643-5" => ':cns5-%d-%d',
        "cns11643-6" => ':cns6-%d-%d',
        "cns11643-7" => ':cns7-%d-%d',
        "gb2312" => ':gb0-%d-%d',
        "gb12345" => ':gb0-%d-%d',
        "iso-ir165" => ':gb0-%d-%d',
        "jis-x0208" => ':jis1-%d-%d',
        'jis-x0208@1978' => ':jis1-%d-%d',
        'jis-x0208@1978/1pr' => ':jis1-%d-%d',
        #'jis-x0208@1978/1pr*note' => 
        'jis-x0208@1978/1pr/fixed' => ':jis1-%d-%d',
        #'jis-x0208@1978/1pr/fixed*sources' => 
        'jis-x0208@1978/-4pr' => ':jis1-%d-%d',
        #'jis-x0208@1978/-4pr*note' => 
        #'jis-x0208@1978/-4pr*sources' => 
        'jis-x0208@1978/-4X' => ':jis1-%d-%d',
        'jis-x0208@1978/2-pr' => ':jis1-%d-%d',
        'jis-x0208@1978/4er' => ':jis1-%d-%d',
        'jis-x0208@1978/4-pr' => ':jis1-%d-%d',
        #'jis-x0208@1978/4-pr*sources' => '
        'jis-x0208@1978/5pr' => ':jis1-%d-%d',
        'jis-x0208@1983' => ':jis1-%d-%d',
        'jis-x0208@1990' => ':jis1-%d-%d',
        'jis-x0208@1997' => ':jis1-%d-%d',
        #'jis-x0208*note' => 
        "jis-x0212" => ':jis2-%d-%d',
        "jis-x0213-1" => ':jis1-%d-%d',
        'jis-x0213-1@2000' => ':jis1-%d-%d',
        'jis-x0213-1@2004' => ':jis1-%d-%d',
        "jis-x0213-2" => ':jis2-%d-%d',
        "ks-x1001" => ':ks0-%d-%d',
      }->{$raw_type} // $AdditionalIds->{$raw_type};
      if ($raw_type =~ /^adobe-japan1-[0-9]+$|^adobe-japan1-base$|^adobe-japan1$/) {
        $pattern = ':aj%d';
      }
      if ($raw_type =~ m{^hanyo-denshi/(j[abcdef]|ft)$}) { # ia ib hg
        $pattern = ':' . (uc $1) . '%02d%02d';
      }
      if ($raw_type =~ m{^chise-hdic-(\w\w\w)$}) {
        $pattern = ":chise-hdic-$1-%d";
      } elsif ($raw_type =~ m{^hng-(\w\w\w)$}) {
        $pattern = ":chise-hng-$1-%d";
      }
      if ($raw_type =~ m{^hanziku-([0-9]+)$}) {
        $pattern = ":b5-hanziku$1-%x";
      }
      if (defined $pattern) {
        if ($pattern eq ':u%x') {
          my $c2 = u_chr $id->[1];
          $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
          next;
        } elsif ($pattern =~ /(?:-%d-%d|%02d%02d)$/) {
          my $c2 = sprintf $pattern, $id->[1] / 0x100 - 0x20, $id->[1] % 0x100 - 0x20;
          $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
          next;
        } elsif ($pattern =~ s/%Lx/%x/g) {
          my $c2 = sprintf $pattern, $id->[1] - 0x80;
          $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
          next;
        } else {
          my $c2 = sprintf $pattern, $id->[1];
          $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
          if ($pattern =~ /^:b5-\w+-/) {
            my $c3 = sprintf ':b5-%x', $id->[1];
            $Data->{rels}->{$c3}->{$c1}->{'manakai:private'} = 1;
          } elsif ($pattern =~ /^:u-\w+-/) {
            my $c3 = u_chr $id->[1];
            $Data->{rels}->{$c3}->{$c1}->{'manakai:private'} = 1;
          }
          next;
        }
      }

      if ($raw_type =~ /^ucs(?:-bmp|-sip|-radicals|-hangul|-bmp-cjk-compat|-sip-ext-b|)(?:\@|\*|$)/) {
        my $c2 = u_chr $id->[1];
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
        next;
      } elsif ($raw_type =~ /^ucs-(?:bmp-|sip-|)(itaiji|var)-([0-9]+)(?:$|\@)/) {
        my $c2 = sprintf ':gw-u%04x-%s-%s', $id->[1], $1, $2;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
        next;
      }

      if ($raw_type =~ /^big5-cdp-(itaiji|var)-([0-9]+)$/) {
        my $c2 = sprintf ':gw-cdp-%04x-%s-%s', $id->[1], $1, $2;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
        next;
      }

      if ($raw_type =~ /^decomposition/) {
        for (@$id) {
          if (ref $_ eq 'ARRAY') {
            my $r = process_ids $_;
            push @more, @$r;
          }
        }
        
        my $operands = [];
        my $s = serialize_string $id, $operands;
        unless (defined $s) {
          # Already reported
          next;
        }

        my $raw_type = $type;
        my $rel_key = $key;
        $raw_type =~ s/^chise:[<>+=-]*//;
        if ({
          'decomposition@square' => 1,
        }->{$raw_type}) {
          $rel_key = 'components';
        }

        my $c2 = (wrap_ids $s, ':chise:ids:') // $s;
        $Data->{$rel_key}->{$c1}->{$c2}->{$type} = 1;
        for my $c3 (@$operands) {
          $Data->{components}->{$c1}->{$c3}->{"componentin:$type"} = 1;
        }
        $Types->{"componentin:$type"} = 1;
        next;
      } # decomposition

      if ($raw_type =~ m{^gt-pj-|^mj-|^hanyo-denshi/\w+/mf}) {
        next;
      }

      #
    } # $id
  } # ID

  for (@$rels) {
    for (@$_) {
      if (ref $_ eq 'ARRAY') {
        my $r = process_ids $_;
        push @more, @$r;
      }
    }
    push @more, ['rel', $c1, $_];
  }

  for (@$idses) {
    for (@$_) {
      if (ref $_ eq 'ARRAY') {
        my $r = process_ids $_;
        push @more, @$r;
      }
    }
    push @more, ['ids', $c1, $_];
  }

  return \@more;
} # process_ids

sub process_rels ($) {
  my (undef, $c1, $rel) = @{$_[0]};

  my $key = 'rels';
  for my $rel ($rel) {
    my $type = "chise:$rel->[0]";
    for my $o (@$rel[1..$#$rel]) {
      my $name;
      for (@$o) {
        if ($_->[0] =~ /^=/ or $_->[0] eq 'name' or
            defined $AdditionalIds->{$_->[0]}) {
          my $this_name = serialize_id $_;
          next unless defined $this_name;
          $name = $NameMap->{$this_name};
          last if defined $name;
        } elsif ($_->[0] eq '_our_name') {
          $name = $_->[1];
          last;
        } elsif ($_->[0] eq 'ideographic-combination') {
          for (@$_) {
            process_ids $_ if ref $_ eq 'ARRAY';
            # need to process recursively here in theory...
          }

          my $s = serialize_string $_, []; # or undef
          my $c2 = (wrap_ids $s, ':chise:ids:') // $s;
          $name = $c2;
        } elsif ($_->[0] eq 'ideographic-structure') {
          my $s = serialize_string $_, []; # or undef
          if (defined $s) {
            my $c2 = (wrap_ids $s, ':chise:ids:');
            if (defined $c2) {
              $name = to_ids_char $c2;
              $Data->{components}->{$name}->{$c2}->{"chise:ideographic-structure"} = 1;
            }
          }
        }
      }
      
      unless (defined $name) {
        #use Data::Dumper;warn Dumper $rel;
        die "No referenced object found";
        next;
      }

      my $c2 = $name;
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    }
  } # $rel
} # process_rels

sub process_idses ($) {
  my (undef, $c1, $ids) = @{$_[0]};
  for my $ids ($ids) {
    my $type = "chise:$ids->[0]";
    my $operands = [];
    my $s = serialize_string $ids, $operands;
    unless (defined $s) {
      # Already reported
      next;
    }
    if ($type eq 'chise:ideographic-combination') {
      my $c2 = (wrap_ids $s, ':chise:ids:') // $s;
      $Data->{components}->{$c1}->{$c2}->{$type} = 1;
      for my $c3 (@$operands) {
        $Data->{components}->{$c1}->{$c3}->{"string:contains"} = 1;
      }
    } else {
      my $c2 = (wrap_ids $s, ':chise:ids:') // die "$type $s";
      $Data->{components}->{$c1}->{$c2}->{$type} = 1;
      for my $c3 (@$operands) {
        $Data->{components}->{$c1}->{$c3}->{"componentin:$type"} = 1;
      }
    }
    $Types->{"componentin:$type"} = 1;
  } # $ids
} # process_idses

{
  my $n = 0;
  my @more;
  while (<>) {
    print STDERR "\r[1][$n]... " if $n++ % 10000 == 0;
    my $obj = json_bytes2perl $_;
    my $r = process_ids $obj;
    push @more, @$r;
  }

  $n = 0;
  my $all = @more;
  for (@more) {
    print STDERR "\r[2][$n/$all]... " if $n++ % 10000 == 0;
    if ($_->[0] eq 'rel') {
      process_rels $_;
    } elsif ($_->[0] eq 'ids') {
      process_idses $_;
    } else {
      die $_->[0];
    }
  }
}

print STDERR "\rWriting... ";
write_rel_data_sets
    $Data => $TempPath, 'chise',
    [];

{
  my $path = $TempPath->child ('chisereltypes.json');
  $path->spew (perl2json_bytes_for_record [sort { $a cmp $b } keys %$Types]);
}
print STDERR "\rDone. \n";

## License: Public Domain.
