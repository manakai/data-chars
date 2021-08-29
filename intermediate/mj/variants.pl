use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/imj');

my $Data = {};

sub ucs ($) {
  my $s = shift;
  if ($s =~ /^U\+([0-9A-F]+)$/) {
    return chr hex $1;
  } else {
    die "Bad UCS code point |$s|"
  }
} # ucs

sub vs ($) {
  my @r;
  for my $s (split /;/, shift) {
    if ($s =~ /^([0-9A-F]+)_([0-9A-F]+)$/) {
      push @r, chr (hex $1) . chr (hex $2);
    } else {
      die "Bad IVS |$s|"
    }
  }
  return \@r;
} # vs

{
  my $MJVariants = [];
  use utf8;
  my $path = $TempPath->child ('mj.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (@$json) {
    my $mj = $data->{MJ文字図形名};
    my $ivses = vs $data->{実装したMoji_JohoコレクションIVS};
    my $impl_ucs = $data->{実装したUCS} ? ucs $data->{実装したUCS} : undef;
    my $ucs = $data->{対応するUCS} ? ucs $data->{対応するUCS} : undef;
    my $char = $Data->{mj_to_char}->{$mj} = $ivses->[0] // $impl_ucs // ':'.$mj;
    if (defined $ucs and not $char eq $ucs) {
      my $type = 'mj:対応するUCS';
      $Data->{variants}->{$char}->{$ucs}->{$type} = 1;
    }
    if (@$ivses > 1) {
      for (1..$#$ivses) {
        my $type = 'mj:実装したMoji_JohoコレクションIVS';
        $Data->{variants}->{$char}->{$ivses->[$_]}->{$type} = 1;
      }
    }
    if ($data->{対応する互換漢字}) {
      my $cchar = ucs $data->{対応する互換漢字}; # or throw
      my $type = 'mj:対応する互換漢字';
      $Data->{variants}->{$char}->{$cchar}->{$type} = 1;
    }
    if ($data->{実装したSVS}) {
      my $svses = vs $data->{実装したSVS};
      die unless @$svses == 1;
      my $type = 'mj:実装したSVS';
      $Data->{variants}->{$char}->{$svses->[0]}->{$type} = 1;
    }
    if ($data->{備考} =~ m{^(MJ[0-9]+)・(MJ[0-9]+)は、戸籍統一文字において、同一字形であり、字義も同一の内容である。$}) {
      my $v1 = $1;
      my $v2 = $2;
      push @$MJVariants, [$1, $2, 'mj:戸籍統一文字:同一'];
    } elsif ($data->{備考} =~ m{^(MJ[0-9]+)は、.+新しいMJ文字図形名は(MJ[0-9]+)となる。}) {
      push @$MJVariants, [$1, $2, 'mj:新しいMJ文字図形名'];
    }
  }

  for (@$MJVariants) {
    my ($v1, $v2, $type) = @$_;
    my $c1 = $Data->{mj_to_char}->{$v1} // die $v1;
    my $c2 = $Data->{mj_to_char}->{$v2} // die $v2;
    $Data->{variants}->{$c1}->{$c2}->{$type} = 1;
  }

  for my $data (@$json) {
    use utf8;
    for (
      [jouyou => '常用漢字'],
      [jinmei => '人名用漢字'],
    ) {
      my ($cat, $value) = @$_;
      if ($data->{漢字施策} eq $value) {
        my $this = {};
        $Data->{stats}->{$cat}->{all}++;

        if ($data->{"実装したSVS"}) {
          die $data->{"実装したSVS"} if $data->{"実装したSVS"} =~ /;/;
          my $str = join '', map { chr hex $_ } split /_/, $data->{"実装したSVS"};
          $Data->{stats}->{$cat}->{svs}++;
          $this->{svs} = $str;
        }
        if ($data->{"実装したMoji_JohoコレクションIVS"}) {
          die $data->{"実装したMoji_JohoコレクションIVS"} if $data->{"実装したMoji_JohoコレクションIVS"} =~ /;/;
          my $str = join '', map { chr hex $_ } split /_/, $data->{"実装したMoji_JohoコレクションIVS"};
          $Data->{stats}->{$cat}->{ivs}++;
          $this->{ivs} = $str;
        }

        if ($data->{"実装したUCS"}) {
          my $c = $data->{"実装したUCS"};
          $c =~ s/^U\+//;
          my $cc = hex $c;
          $Data->{stats}->{$cat}->{char}++;
          $this->{char} = chr $cc;
        }
        if ($data->{"対応する互換漢字"}) {
          my $c = $data->{"対応する互換漢字"};
          $c =~ s/^U\+//;
          my $cc = hex $c;
          $Data->{stats}->{$cat}->{compat}++;
          $this->{compat} = chr $cc;
        }
        if ($data->{"対応するUCS"}) {
          my $c = $data->{"対応するUCS"};
          $c =~ s/^U\+//;
          my $cc = hex $c;
          $Data->{stats}->{$cat}->{fallback_char}++;
          $this->{fallback_char} = chr $cc;
        }

        if (defined $this->{char} and defined $this->{compat}) {
          if ($this->{char} eq $this->{compat}) {
            $Data->{stats}->{$cat}->{char_is_compat}++;
            $this->{char_is_compat} = 1;
          } else {
            $Data->{stats}->{$cat}->{char_not_compat}++;
          }
        }

        if (defined $this->{char} and not defined $this->{ivs}) {
          $Data->{stats}->{$cat}->{char_only}++;
          if (defined $this->{svs}) {
            $Data->{stats}->{$cat}->{char_compat_only}++;
          }
        }

        if (defined $this->{char} and defined $this->{ivs} and
            not $this->{char_is_compat}) {
          $Data->{stats}->{$cat}->{char_unified_ivs}++;
        }

        if (not defined $this->{char} and defined $this->{ivs}) {
          $Data->{stats}->{$cat}->{ivs_only}++;
        }

        if ($this->{char_is_compat}) {
          $Data->{sets}->{$cat}->{$this->{char}} = 1;
        } elsif (defined $this->{ivs}) {
          $Data->{sets}->{$cat}->{$this->{ivs}} = 1;
        } elsif (defined $this->{char}) {
          $Data->{sets}->{$cat}->{$this->{char}} = 1;
        } else {
          die "Bad char";
        }
      }
    }
  } # $data
} # mj.json

{
  use utf8;
  my $path = $TempPath->child ('map.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (@{$json->{content}}) {
    my $mj = $data->{MJ文字図形名};
    next if $mj eq 'MJ037229' or
        $mj eq 'MJ040579' or
        $mj eq 'MJ042077';
    my $char = $Data->{mj_to_char}->{$mj}
        or die "Bad MJ |$mj|";
    for my $type ('JIS包摂規準・UCS統合規則',
                  '法務省告示582号別表第四',
                  '法務省戸籍法関連通達・通知',
                  '辞書類等による関連字',
                  '読み・字形による類推') {
      for (@{$data->{$type} or []}) {
        if (not $_->{UCS}) {
          use Data::Dumper;
          warn Dumper $_;
        }
        my $uc = ucs $_->{UCS};
        my $tt = "mj:$type";
        $tt .= ':' . $_->{種別} if defined $_->{種別};
        $tt .= ':' . $_->{表} if defined $_->{表};
        $tt .= ':' . $_->{順位} if defined $_->{順位};
        $tt .= ':' . $_->{ホップ数} if defined $_->{ホップ数} and
            $_->{ホップ数} > 1;
        $Data->{variants}->{$char}->{$uc}->{$tt} = 1;
      }
    }
  }
}

delete $Data->{mj_to_char};
print perl2json_bytes_for_record $Data;

## License: Public Domain.
