package POE::Component::YahooMessenger;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

use POE qw(Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW
	   Filter::Stream Filter::YahooMessengerPacket);
use Socket;			# for constants
use Net::YahooMessenger::CRAM;
use POE::Component::YahooMessenger::Constants;

sub spawn {
    my($class, %args) = @_;
    $args{Alias} ||= 'ym';
    POE::Session->create(
	inline_states => {
	    _start     => \&_start,
	    _stop      => \&_stop,
	    _sock_up   => \&_sock_up,
	    _sock_down => \&_sock_down,

	    # API
	    register   => \&register,
	    unregister => \&unregister,
	    connect    => \&connect,
	    send_message     => \&send_message,
	    change_my_status => \&change_my_status,
	    buddies          => \&buddies,

	    # internals
	    login             => \&login,
	    notify            => \&notify,
	    _unregister       => \&_unregister,
	    handle_event      => \&handle_event,

	    # own callbacks
	    goes_online      	=> \&goes_online,
	    goes_offline     	=> \&goes_offline,
	    change_status    	=> \&_handle_common,
	    receive_message  	=> \&_handle_common,
	    new_friend_alert 	=> \&_handle_common,
	    toggle_typing 	=> \&_handle_common,
	    server_is_alive 	=> \&_handle_common,
	    cram_auth_fail 	=> \&_handle_common,
	    receive_buddy_list	=> \&receive_buddy_list,
	    challenge_start 	=> \&challenge_start,
	},
	args => [ \%args ],
    );
}

sub _start {
    my($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
    $kernel->alias_set($args->{Alias});
}

sub _stop { }

sub register {
    my($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    $kernel->refcount_increment($sender->ID, __PACKAGE__);
    $heap->{listeners}->{$sender->ID} = 1;
}

sub unregister {
    my($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    $kernel->yield(_unregister => $sender->ID);
}

sub _unregister {
    my($kernel, $heap, $session) = @_[KERNEL, HEAP, ARG0];
    $kernel->refcount_decrement($session, __PACKAGE__);
    delete $heap->{listeners}->{$session};
}

sub notify {
    my($kernel, $heap, $name, $event) = @_[KERNEL, HEAP, ARG0, ARG1];
    $event ||= POE::Component::YahooMessenger::Event::Null->new;
    $kernel->post($_ => "ym_$name" => $event) for keys %{$heap->{listeners}};
}

sub connect {
    my($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];

    # set up parameters
    $heap->{$_} = $args->{$_}
	for qw(id password);
    $heap->{$_} = $args->{$_} || $Default->{$_}
	for qw(hostname port);

    return if $heap->{sock};
    $heap->{sock} = POE::Wheel::SocketFactory->new(
	SocketDomain   => AF_INET,
	SocketType     => SOCK_STREAM,
	SocketProtocol => 'tcp',
	RemoteAddress  => $heap->{hostname},
	RemotePort     => $heap->{port},
	SuccessEvent   => '_sock_up',
	FailureEvent   => '_sock_failed',
    );
}

sub _sock_up {
    my($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];

    # new ReadWrite wheel for the socket
    $heap->{sock} = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	Driver => POE::Driver::SysRW->new,
	Filter  => POE::Filter::YahooMessengerPacket->new,
	ErrorEvent => '_sock_down',
    );
    $heap->{sock}->event(InputEvent => 'handle_event');
    $heap->{connected} = 1;
    $kernel->yield(notify => connected => ());
    $kernel->yield(login => ());
}

sub _sock_down {
    my($kernel, $heap) = @_[KERNEL, HEAP];
    delete $heap->{sock};
    $heap->{connected} = 0;
    $kernel->yield(notify => disconnected => ());
    for my $session (keys %{$heap->{listeners}}) {
	$kernel->yield(_unregister => $session);
    }
}

sub handle_event {
    my($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];
    # check if event is implemented
    if ($event->name) {
	$kernel->yield($event->name, $event);
    }
}

sub login {
    my($kernel, $heap) = @_[KERNEL, HEAP];
    $heap->{sock}->put(
	POE::Component::YahooMessenger::Event->new(
	    'challenge_start', 0, {
		my_id => $heap->{id},
	    },
	),
    );
}

sub _handle_common {
    $_[KERNEL]->yield(notify => $_[ARG0]->name, $_[ARG0]);
}

sub challenge_start {
    my($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];

    # calculate CRAM
    my $cram = Net::YahooMessenger::CRAM->new;
    $cram->set_id($heap->{id});
    $cram->set_password($heap->{password});
    $cram->set_challenge_string($event->challenge_string);
    my($response_password, $response_crypt) = $cram->get_response_strings;

    $heap->{sock}->event(InputEvent => 'handle_event');
    $heap->{sock}->put(
	POE::Component::YahooMessenger::Event->new(
	    'challenge_response', 0, {
		my_id  => $heap->{id},
		crypt_salt => $response_password,
		crypted_response => $response_crypt,
		login_nickname  => 1,
		id => $heap->{id},
	    },
	),
    );
    $kernel->yield(notify => $event->name, $event);
}

sub receive_buddy_list {
    my($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];
    my $buddy_list = $event->buddy_list;
    while ($buddy_list =~ /([^:]+):([^\x0a]+)\x0a/g) {
	my $group = $1;
	$heap->{buddies}->{$group} = [ split /,/, $2 ];
    }
    $kernel->yield(notify => $event->name, $event);
}

sub goes_online {
    my($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];
    $heap->{online}->{$event->id} = 1;
    $kernel->yield(notify => $event->name, $event);
}

sub goes_offline {
    my($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];
    delete $heap->{online}->{$event->id};
    $kernel->yield(notify => $event->name, $event);
}

sub send_message {
    my($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
    $heap->{sock}->put(
	POE::Component::YahooMessenger::Event->new(
	    'send_message', 1515563606, {
		from => $heap->{id},
		to   => $args->{to},
		message => $args->{message},
	    },
	),
    );
}

sub change_my_status {
    my($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
    $heap->{sock}->put(
	POE::Component::YahooMessenger::Event->new(
	    'change_status', 0, {
		status_code => 99, # XXX custom status
		busy_code => $args->{busy} || 0,
		status_message => $args->{message},
	    },
	),
    );
}

sub buddies {
    my($kernel, $heap, $sender, $reply) = @_[KERNEL, HEAP, SENDER, ARG0];
    $kernel->post($sender => $reply => $heap->{buddies});
}

1;
__END__

=head1 NAME

POE::Component::YahooMessenger - POE component for Yahoo! Messenger

=head1 SYNOPSIS

  use POE qw(Component::YahooMessenger);

  # spawn YM session
  POE::Component::YahooMessenger->spawn(Alias => 'ym');

  # register your session for callbacks
  $kernel->post(ym => 'register');

  # tell YM how to connect
  $kernel->post(ym => connect => {
      id       => 'your_id',
      password => 'xxxxxxx',
  });

  # associate this callback with 'ym_goes_online'
  sub goes_online {
      my $event = $_[ARG0];
      printf "buddy %s goes online\n", $event->buddy_id;
  }

  # send message
  $kernel->post(ym => send_message => {
      to => $buddy_id,
      message => "Hello World",
  });

  # change your status
  $kernel->post(ym => change_my_status => {
      busy => 0, # 0 = not busy
      message => "going for lunch now!",
  });

  # retrieve your buddies list
  $kernel->post(ym => buddies => 'retrieve_buddies');
  sub retrieve_buddies {
      my $buddies = $_[ARG0];
      for my $group (keys %$buddies) {
	  print "$group:\n", map "  $_\n", @{$buddies->{$group}};
      }
  }

  $poe_kernel->run();

=head1 DESCRIPTION

POE::Component::YahooMessenger is a POE component to connect Yahoo!
Messener. This module ripoffs a lot of code from Net::YahooMessenger
for protocol implementations.

API is intentionally made similar to that of PoCo::IRC.

=head1 EVENTS

TBD.

=head1 CAVEATS

B<This is ALPHA SOFTWARE>: There maybe some bugs. API might change.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

YahooMessenger protocol implementation is based on Net::YahooMessenger
by Hiroyuki Oyama E<lt>oyama[cpan.orgE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POE>, L<POE::Component::IRC>, L<Net::YahooMessenger>, http://ymca.infoware.ne.jp/

=cut
