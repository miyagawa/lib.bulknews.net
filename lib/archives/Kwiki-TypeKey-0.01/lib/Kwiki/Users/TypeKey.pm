package Kwiki::Users::TypeKey;
use strict;
use Authen::TypeKey;

our $VERSION = 0.01;
use Kwiki::Users '-Base';

const class_id    => "users";
const class_title => "Kwiki users from TypeKey authentication";
const user_class  => "Kwiki::User::TypeKey";

sub init {
    $self->hub->config->add_file('typekey.yaml');
    io($self->plugin_directory)->mkdir;
}

sub current {
    return $self->{current} = shift if @_;
    return $self->{current} if defined $self->{current};
    $self->{current} = $self->new_user();
}

sub new_user {
    $self->user_class->new(hub => $self->hub);
}

package Kwiki::User::TypeKey;
use base qw(Kwiki::User);

field 'email';
field 'name';
field 'nick';
field 'ts';

sub set_user_name {
    return unless $self->is_in_cgi;
    my $name = '';
    my $cookie = $self->hub->cookie->jar->{typekey} or return;

    $self->validate_sig($cookie) or return;
    for my $key (qw(email name nick ts)) {
	$self->$key($cookie->{$key});
    }
}

sub validate_sig {
    my $data = shift;
    require CGI;
    my $q = CGI->new({ %$data });
    my $tk = Authen::TypeKey->new();
    $tk->key_cache($self->hub->config->tk_key_cache);
    $tk->token($self->hub->config->tk_token);
    $tk->expires($self->hub->config->tk_expires);
    $tk->verify($q);
}

package Kwiki::Users::TypeKey;
1;

__DATA__

__config/typekey.yaml__
tk_token: PUT YOUR TOKEN HERE
tk_expires: 604800
tk_key_cache: plugin/users/keycache.txt
