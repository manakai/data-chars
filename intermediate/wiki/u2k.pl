use strict;
use warnings;
use JSON::PS;

{
  package SReader;

  sub new {
    my ($class, %opt) = @_;
    bless {
      file    => $opt{file} // '<stdin>',
      on_sexp => $opt{on_sexp},

      stack   => [],
      token   => undef,

      in_str  => 0,
      escape  => 0,
      comment => 0,

      pos     => 0,
      around  => '',
    }, $class;
  } # new

  sub feed {
    my ($self, $c) = @_;

    $self->{pos}++;
    $self->{around} .= $c;
    substr ($self->{around}, 0, -40) = '' if length $self->{around} > 40;

    if (!$self->{in_str} && $c eq ';') {
      $self->{comment} = 1;
      return;
    }
    if ($self->{comment}) {
      $self->{comment} = 0 if $c eq "\n";
      return;
    }

    if ($self->{in_str}) {
        if ($self->{escape}) {
            $self->{token} .= $c;
            $self->{escape} = 0;
        }
        elsif ($c eq '\\') {
            $self->{escape} = 1;
        }
        elsif ($c eq '"') {
            $self->_push_token($self->{token});
            $self->{token} = undef;
            $self->{in_str} = 0;
        }
        else {
            $self->{token} .= $c;
        }
        return;
    }

    if ($c =~ /\s/) {
        $self->_flush_token;
        return;
    }

    if ($c eq '(' || $c eq ')' || $c eq '.') {
        $self->_flush_token;
        $self->_emit($c);
        return;
    }

    if ($c eq '"') {
        $self->{in_str} = 1;
        $self->{token} = '';
        return;
    }

    if ($c eq "'") {
        return;
    }

    if ($c =~ /[^\s()";]/) {
        $self->{token} .= $c;
        return;
    }

    die $self->_error("unexpected character '$c'");
  }

  sub _emit {
    my ($self, $tok) = @_;

    if ($tok eq '(') {
        push @{ $self->{stack} }, [];
        return;
    }

    if ($tok eq ')') {
        my $list = pop @{ $self->{stack} }
            or die $self->_error("unmatched ')'");

        my $node = $self->_list_to_value($list);

        if (@{ $self->{stack} }) {
            push @{ $self->{stack}[-1] }, $node;
        }
        else {
            $self->{on_sexp}->($node);
        }
        return;
    }

    push @{ $self->{stack}[-1] }, '.'
        if @{ $self->{stack} };
  } # _emit

sub _flush_token {
    my ($self) = @_;
    return unless defined $self->{token};
    $self->_push_token($self->{token});
    $self->{token} = undef;
}

sub _push_token {
    my ($self, $tok) = @_;

    my $val;
    if ($tok eq 'nil') {
        $val = undef;
    }
    elsif ($tok eq 't') {
        $val = 1;
    }
    elsif ($tok =~ /^#x([0-9A-Fa-f]+)$/) {
        $val = hex($1);
    }
    elsif ($tok =~ /^-?\d+$/) {
        $val = int($tok);
    }
    else {
        $val = $tok;
    }

    push @{ $self->{stack}[-1] }, $val
        if @{ $self->{stack} };
}

sub _list_to_value {
    my ($self, $list) = @_;

    if (
        @$list == 3
        && defined $list->[1]
        && !ref $list->[1]
        && $list->[1] eq '.'
    ) {
        return [ $list->[0] => $list->[2] ];
    }

    return $list;
}

sub _error {
    my ($self, $msg) = @_;
    my $ctx = $self->{around};
    $ctx =~ s/\n/\\n/g;
    return sprintf(
        "lexical error: %s\n  file: %s\n  pos: %d\n  context: ...%s\n",
        $msg,
        $self->{file},
        $self->{pos},
        $ctx,
    );
  }
}

sub parse_elisp_files ($$) {
  my ($dir, $handler) = @_;

  my @file = sort { $a cmp $b } glob "$dir/*.el";
  my $n = 0;
  my $all = @file;
  for my $file (@file) {
    open my $fh, '<:utf8', $file or die "open $file: $!";
    print STDERR "\r[$n/$all] Processing |@{[[split m{/}, $file]->[-1]]}|... "; $n++;
    
    my $reader = SReader->new (
      file    => $file,
      on_sexp => sub {
        my ($sexp) = @_;

        return unless ref $sexp eq 'ARRAY';
        return unless $sexp->[0] eq 'define-char';

        $handler->($sexp->[1]);
      },
    );

    while (read ($fh, my $c, 1)) {
      $reader->feed ($c);
    }

    close $fh;
  }
  print STDERR "\rDone. \n";
} # parse_elisp_files

my $dir = shift or die "Usage: $0 DIR\n";
parse_elisp_files ($dir, sub {
  my ($obj) = @_;
  print perl2json_bytes $obj;
  print "\x0A";
});

## License: Public Domain.
