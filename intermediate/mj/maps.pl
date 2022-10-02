use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/imj');

sub u_chr ($) {
  if ($_[0] <= 0x1F or (0x7F <= $_[0] and $_[0] <= 0x9F)) {
    return sprintf ':u%x', $_[0];
  }
  my $c = chr $_[0];
  if ($c eq ":" or $c eq "." or
      $c =~ /\p{Non_Character_Code_Point}|\p{Surrogate}/) {
    return sprintf ':u%x', $_[0];
  } else {
    return $c;
  }
} # u_chr

sub u_hexs ($) {
  my $s = shift;
  my $i = 0;
  return join '', map {
    my $t = u_chr hex $_;
    if ($i++ != 0) {
      $t = '.' if $t eq ':u2e';
      $t = ':' if $t eq ':u3a';
    }
    if (1 < length $t) {
      return join '', map {
        sprintf ':u%x', hex $_;
      } split /\s+/, $s;
    }
    $t;
  } split /\s+/, $s
} # u_hexs

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

my $Data = {};

{
  my $path = $TempPath->child ('mj.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (@$json) {
    my $c1 = ':' . $data->{MJ文字図形名};
    
    if ($data->{X0212} =~ /^([0-9]+)-([0-9]+)$/) {
      my $c2 = sprintf ':jis2-%d-%d', $1, $2;
      $Data->{variants}->{$c1}->{$c2}->{"mj:X0212"} = 1;
    } elsif ($data->{X0213} =~ /^([0-9]+)-([0-9]+)-([0-9]+)$/) {
      my $c2 = sprintf ':jis%d-%d-%d', $1, $2, $3;
      my $suffix = '';
      unless ($data->{"X0213 包摂区分"} eq "0") {
        $suffix = ':' . $data->{"X0213 包摂区分"};
      }
      $Data->{variants}->{$c1}->{$c2}->{"mj:X0213$suffix"} = 1;
    }

    my $ivses = vs $data->{実装したMoji_JohoコレクションIVS};
    for (@$ivses) {
      my $type = 'mj:実装したMoji_JohoコレクションIVS';
      $Data->{variants}->{$c1}->{$_}->{$type} = 1;
    }
    my $svses = vs $data->{実装したSVS};
    for (@$svses) {
      my $type = 'mj:実装したSVS';
      $Data->{variants}->{$c1}->{$_}->{$type} = 1;
    }
    
    my $impl_ucs = $data->{実装したUCS} ? ucs $data->{実装したUCS} : undef;
    if (defined $impl_ucs) {
      my $type = 'mj:実装したUCS';
      $Data->{variants}->{$c1}->{$impl_ucs}->{$type} = 1;
    }
    my $ucs = $data->{対応するUCS} ? ucs $data->{対応するUCS} : undef;
    if (defined $ucs) {
      my $type = 'mj:対応するUCS';
      $Data->{variants}->{$c1}->{$ucs}->{$type} = 1;
    }
    my $compat = $data->{対応する互換漢字} ? ucs $data->{対応する互換漢字} : undef;
    if (defined $compat) {
      my $type = 'mj:対応する互換漢字';
      $Data->{variants}->{$c1}->{$compat}->{$type} = 1;
    }

  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.

