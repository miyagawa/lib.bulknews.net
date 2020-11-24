package POE::Component::MSN;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

use vars qw($Default);
$Default = {
    port => 1863,
    hostname => 'messenger.hotmail.com',
};

use POE qw(Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW Filter::Line Filter::Stream
	   Filter::MSN);
use POE::Component::MSN::Command;

use Digest::MD5 qw(md5_hex);
use Socket;

sub spawn {
    my($class, %args) = @_;
    $args{Alias} ||= 'msn';
    POE::Session->create(
	inline_states => {
	    _start => \&_start,
	    _stop  => \&_stop,

	    # internals
	    _sock_up   => \&_sock_up,
	    _sock_down => \&_sock_down,
	    _sb_sock_up => \&_sb_sock_up,

	    # API
	    notify     => \&notify,
	    register   => \&register,
	    unregister => \&unregister,
	    connect    => \&connect,
	    login      => \&login,

	    handle_event => \&handle_event,

	    # commands
	    VER => \&got_version,
	    INF => \&got_info,
	    XFR => \&got_xfer,
	    USR => \&got_user,
	    LST => \&got_list,
	    NLN => \&got_online,
	    FLN => \&got_offline,
	    RNG => \&got_ring,
	},
	args => [ \%args ],
    );
}

sub _start {
    $_[KERNEL]->alias_set($_[ARG0]->{Alias});
    $_[HEAP]->{transaction} = 0;
}

sub _stop { }

sub register {
    my($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    $kernel->refcount_increment($sender->ID, __PACKAGE__);
    $heap->{listeners}->{$sender->ID} = 1;
}

sub unregister {
    my($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    $kernel->refcount_decrement($sender->ID, __PACKAGE__);
    delete $heap->{listeners}->{$sender->ID};
}

sub notify {
    my($kernel, $heap, $name, $event) = @_[KERNEL, HEAP, ARG0, ARG1];
#    $event ||= POE::Component::MSN::Event::Null->new;
    $kernel->post($_ => "msn_$name" => $event) for keys %{$heap->{listeners}};
}

sub connect {
    my($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];

    # set up parameters
    $heap->{$_} = $args->{$_}
	for qw(username password);
    $heap->{$_} = $args->{$_} || $Default->{$_}
	for qw(hostname port);

    return if $heap->{sock};
    $heap->{sock} = POE::Wheel::SocketFactory->new(
	SocketDomain => AF_INET,
	SocketType => SOCK_STREAM,
	SocketProtocol => 'tcp',
	RemoteAddress => $heap->{hostname},
	RemotePort => $heap->{port},
	SuccessEvent => '_sock_up',
	FailureEvent => '_sock_failed',
    );
}

sub _sock_up {
    my($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];

    # new ReadWrite wheel for the socket
    $heap->{sock} = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	Driver => POE::Driver::SysRW->new,
	Filter => POE::Filter::MSN->new,
	ErrorEvent => '_sock_down',
    );
    $heap->{sock}->event(InputEvent => 'handle_event');
    $heap->{sock}->put(
	POE::Component::MSN::Command->new(VER => 'MSNP2' => $heap),
    );
}

sub _sock_down {
    delete $_[HEAP]->{sock};
}

sub handle_event {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
    $kernel->yield($command->name, $command);
}

sub got_version {
    $_[HEAP]->{sock}->put(
	POE::Component::MSN::Command->new(INF => "" => $_[HEAP]),
    );
}

sub got_info {
    $_[HEAP]->{sock}->put(
	POE::Component::MSN::Command->new(USR => "MD5 I $_[HEAP]->{username}" => $_[HEAP]),
    );
}

sub got_xfer {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
    if ($command->args->[0] eq 'NS') {
	@{$heap}{qw(hostname port)} = split /:/, $command->args->[1];
	# switch Notification Server
	$_[HEAP]->{sock} = POE::Wheel::SocketFactory->new(
	    SocketDomain => AF_INET,
	    SocketType => SOCK_STREAM,
	    SocketProtocol => 'tcp',
	    RemoteAddress => $heap->{hostname},
	    RemotePort => $heap->{port},
	    SuccessEvent => '_sock_up',
	    FailureEvent => '_sock_failed',
	);
    }
}

sub got_user {
    if ($_[ARG0]->args->[1] eq 'S') {
	my $challenge = $_[ARG0]->args->[2];
	my $response = md5_hex($challenge . $_[HEAP]->{password});
	$_[HEAP]->{sock}->put(
	    POE::Component::MSN::Command->new(USR => "MD5 S $response" => $_[HEAP]),
	);
    } elsif ($_[ARG0]->args->[0] eq 'OK') {
	$_[HEAP]->{sock}->put(
	    POE::Component::MSN::Command->new(CHG => 'NLN' => $_[HEAP]),
	);
	$_[HEAP]->{sock}->put(
	    POE::Component::MSN::Command->new(SYN => 0 => $_[HEAP]),
	);
    }
}

sub got_list {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
    my($type, $buddy, $nickname) = ($command->args)[0,4,5];
    if ($type eq 'FL') {	# Forward List
	$heap->{buddies}->{$buddy} = $nickname;
    }
    $kernel->yield(notify => buddy_list => $command);
}

sub got_online {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
    my($buddy, $nickname) = ($command->args)[0, 1];
    $heap->{online}->{$buddy} = $nickname;
    $kernel->yield(notify => goes_online => $command);
}

sub got_offline {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
    delete $heap->{online}->{$command->args->[0]};
    $kernel->yield(notify => goes_offline => $command);
}

sub got_ring {
    my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
    POE::Session->create(
	inline_states => {
	    _start => \&sb_start,
	    _sb_sock_up => \&sb_sock_up,
	    _sb_sock_down => \&sb_sock_down,
	    handle_event => \&sb_handle_event,
	    MSG => \&sb_got_message,
	    send_message => \&sb_send_message,
	},
	args => [ $command, $session->ID, $heap ],
    );
}

sub sb_start {
    my($kernel, $heap, $command, $parent, $old_heap) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    $heap->{parent} = $parent;
    $heap->{session} = $command->transaction;
    $heap->{transaction} = $old_heap->{transaction} + 1;
    $heap->{username} = $old_heap->{username};
    @{$heap}{qw(hostname port)} = split /:/, $command->args->[0];
    $heap->{key} = $command->args->[2];
    $heap->{buddy} = $command->args->[3];
    $heap->{sock} = POE::Wheel::SocketFactory->new(
	SocketDomain => AF_INET,
	SocketType => SOCK_STREAM,
	SocketProtocol => 'tcp',
	RemoteAddress => $heap->{hostname},
	RemotePort => $heap->{port},
	SuccessEvent => '_sb_sock_up',
	FailureEvent => '_sb_sock_failed',
    );
}

sub sb_sock_up {
    my($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];
    $heap->{sock} = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	Driver => POE::Driver::SysRW->new,
	Filter => POE::Filter::MSN->new,
	ErrorEvent => '_sb_sock_down',
    );
    $heap->{sock}->event(InputEvent => 'handle_event');
    $heap->{sock}->put(
	POE::Component::MSN::Command->new(
	    ANS => "$heap->{username} $heap->{key} $heap->{session}" => $heap,
	),
    );
}

sub sb_sock_down {
    delete $_[HEAP]->{sock};
}

sub sb_handle_event {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
    $kernel->yield($command->name, $command);
}

sub sb_got_message {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
    $kernel->post($heap->{parent} => notify => got_message => $command);
}

sub sb_send_message {
    my($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
    
}


1;
__END__

=head1 NAME

POE::Component::MSN - POE Component for MSN Messenger

=head1 SYNOPSIS

  use POE qw(Component::MSN);

  # spawn MSN session
  POE::Component::MSN->spawn(Alias => 'msn');

  # register your session as MSN observer
  $kernel->post(msn => 'register');
  # tell MSN how to connect servers
  $kernel->post(msn => connect => {
      username => 'yourname',
      password => 'xxxxxxxx',
  });

  sub msn_goes_online {
      my $event = $_[ARG0];
      print $event->username, " goes online.\n";
  }

  $poe_kernel->run;

=head1 DESCRIPTION

POE::Component::MSN is a POE component to connect MSN Messenger server.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

MSN protocol implementation is based on MSN.pm by Adam Swann
E<lt>http://www.adamswann.com/library/2002/msn-perl/E<gt> and Johannes
Verelst E<lt>http://www.verelst.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POE>, L<POE::Component::YahooMessenger>, http://www.tlsecurity.net/Textware/Misc/draft-movva-msn-messenger-protocol-00.txt

=cut
