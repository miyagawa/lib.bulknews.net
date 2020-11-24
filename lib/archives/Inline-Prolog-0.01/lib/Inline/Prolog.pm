package Inline::Prolog;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Inline);

use Data::Dumper;
use Language::Prolog;

sub _croak { require Carp; Carp::croak(@_) }

sub register {
    return {
	language => 'Prolog',
	aliases  => [ qw(prolog) ],
	type     => 'interpreted',
	suffix  => 'pl',
    };
}

sub validate { }

sub build {
    my $self = shift;
    my $code = $self->{API}->{code};
    my @rules = $code =~ /^\s*(\w*?)\(.*?\)\s*:-/gm;


    my $script = 'my ' . Data::Dumper->Dump([$code], ['code']);
    $script .= q{
	while ($code) {
	    Language::Prolog::Interpreter->readStatement(\$code);
	    $code =~ s/^\s*//;
	}
    };

    for my $rule (@rules) {
	$script .= sprintf <<'CODE', $rule, $rule;
sub %s {
    my @args = @_;
    my $code = '?- %s(' . join(',', map { 'ARG' . $_ } 0..$#args) . ').';
    my $query = Language::Prolog::Interpreter->readStatement(\$code);
    return sub {
	$query->query or return;
	for my $num (0..$#args) {
	    ${$args[$num]} = $query->variableResult('ARG' . $num);
        }
	return 1;
    };
}
CODE
}

    my $path = "$self->{API}->{install_lib}/auto/$self->{API}->{modpname}";
    $self->mkpath($path) unless -d $path;

    my $obj = $self->{API}->{location};
    open PROLOG_OBJ, "> $obj" or _croak "$obj: $!";
    print PROLOG_OBJ $script;
    close PROLOG_OBJ;
}

sub load {
    my $self = shift;
    my $obj = $self->{API}->{location};

    open PROLOG_OBJ, "< $obj" or _croak "$obj: $!";
    my $code = do { local $/; <PROLOG_OBJ> };
    close PROLOG_OBJ;

    eval "package $self->{API}->{pkg};\n$code";
    _croak "Can't load Prolog module $obj: $@" if $@;
}

sub info { }

1;
__END__

=head1 NAME

Inline::Prolog - Write Perl subroutines in Prolog

=head1 SYNOPSIS

  use Inline 'Prolog';

  my $query = grandparent(\my $gparent, \my $gchild);
  while ($query->()) {
      print "$gparent - $gchild matches\n";
  }

  __END__
  __Prolog__
  parent(john,sally).
  parent(john,joe).
  parent(mary,joe).
  parent(phil,beau).
  parent(jane,john).
  grandparent(X,Z) :- parent(X,Y),parent(Y,Z).

=head1 DESCRIPTION

B<THIS IS ALPHA SOFTWARE>

Inline::Prolog allows you to do logical Programming in Perl.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Inline>, L<Language::Prolog>

=cut
