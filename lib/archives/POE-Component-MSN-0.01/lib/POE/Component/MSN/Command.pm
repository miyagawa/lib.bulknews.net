package POE::Component::MSN::Command;
use strict;
use Mail::Internet;

sub new {
    my($class, $name, $data, $stuff) = @_;
    my $transaction = ref($stuff) eq 'HASH' # heap?
	? $stuff->{transaction}++ : $stuff;
    bless {
	name => $name,
	data => $data,
	transaction => $transaction,
	message => undef,
    }, $class;
}

sub name { shift->{name} }
sub data { shift->{data} }
sub transaction { shift->{transaction} }

sub message {
    my $self = shift;
    if (@_) {
	$self->{message} = Mail::Internet->new([ split /\r\n/, shift ]);
    }
    return $self->{message};
}

sub body {
    my $self = shift;
    return join '', map "$_\n", @{$self->message->body};
}

sub header {
    my($self, $key) = @_;
    my $value = $self->message->head->get($key);
    chomp($value);
    return $value;
}

sub args {
    my $self = shift;
    my @data = split / /, $self->data;
    return wantarray ? @data : \@data;
}

1;
