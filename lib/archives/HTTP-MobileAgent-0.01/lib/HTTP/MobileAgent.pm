package HTTP::MobileAgent;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

use HTTP::MobileAgent::Request;

require HTTP::MobileAgent::DoCoMo;
require HTTP::MobileAgent::JPhone;
require HTTP::MobileAgent::EZweb;
require HTTP::MobileAgent::NonMobile;

use vars qw($MobileAgentRE);
# this matching should be robust enough
# detailed analysis is done in subclass's parse()
my $DoCoMoRE = '^DoCoMo/\d\.\d[ /]';
my $JPhoneRE = '^J-PHONE/\d\.\d';
my $EZwebRE  = '^(?:KDDI-[A-Z]+\d+ )?UP\.Browser\/';

$MobileAgentRE = qr/(?:($DoCoMoRE)|($JPhoneRE)|($EZwebRE))/;

sub new {
    my($class, $stuff) = @_;
    my $request = HTTP::MobileAgent::Request->new($stuff);

    # parse UA string
    my $ua = $request->get('User-Agent');
    $ua =~ /$MobileAgentRE/;
    my $sub = $1 ? 'DoCoMo' : $2 ? 'JPhone' : $3 ? 'EZweb' : 'NonMobile';

    my $self = bless { _request => $request }, "$class\::$sub";
    $self->parse;
    return $self;
}

sub user_agent {
    my $self = shift;
    $self->get_header('User-Agent');
}

sub get_header {
    my($self, $header) = @_;
    $self->{_request}->get($header);
}

# should be implemented in subclasses
sub parse { die }

sub name  { shift->{name} }

# Here sare defaults
sub is_mobile     { 1 }
sub is_docomo     { 0 }
sub is_j_phone    { 0 }
sub is_ezweb      { 0 }

# utility for subclasses
sub make_accessors {
    my($class, @attr) = @_;
    for my $attr (@attr) {
	no strict 'refs';
	*{"$class\::$attr"} = sub { shift->{$attr} };
    }
}

sub no_match {
    my $self = shift;
    require Carp;
    Carp::carp($self->user_agent, ": no match. Might be new variants. ",
	       "please contact the author of HTTP::MobileAgent!") if $^W;
    bless $self, 'HTTP::MobileAgent::NonMobile';
    $self->parse;
}

1;
__END__

=head1 NAME

HTTP::MobileAgent - HTTP mobile user agent string parser

=head1 SYNOPSIS

  use HTTP::MobileAgent;

  my $agent = HTTP::MobileAgent->new(Apache->request);
  # or $agent = HTTP::MobileAgent->new; to get from %ENV
  # or $agent = HTTP::MobileAgent->new($agent_string);

  if ($agent->is_docomo) {
      # or if ($agent->name eq 'DoCoMo')
      # or if ($agent->isa('HTTP::MobileAgent::DoCoMo'))
      # it's NTT DoCoMo i-mode.
      # see what's available in H::MA::DoCoMo
  } elsif ($agent->is_j_phone) {
      # it's J-Phone.
      # see what's available in H::MA::JPhone
  } elsif ($agent->is_ezweb) {
      # it's KDDI/EZWeb.
      # see what's available in H::MA::EZweb
  } else {
      # may be PC
      # $agent is H::MA::NonMobile
  }

=head1 DESCRIPTION

HTTP::MobileAgent parses HTTP_USER_AGENT strings of (mainly Japanese)
mobile HTTP user agents. It'll be useful in page dispatching by user agents.

=head1 METHODS

Here are common methods of HTTP::MobileAgent subclasses. More agent
specific methods are described in each subclasses. Note that some of
common methods are also overrided in some subclasses.

=over 4

=item new

  $agent = HTTP::MobileAgent->new;
  $agent = HTTP::MobileAgent->new($r);	# Apache or HTTP::Request
  $agent = HTTP::MobileAgent->new($ua_string);

parses HTTP headers and constructs HTTP::MobileAgent subclass
instance. If no argument is supplied, $ENV{HTTP_*} is used.

Note that you nees to pass Aapche or HTTP::Requet object to new(), as
some mobile agents put useful information on HTTP headers other than
only C<User-Agent:> (like C<x-jphone-msname> in J-Phone).

=item user_agent

  print "User-Agent: ", $agent->user_agent;

returns User-Agent string.

=item name

  print "name: ", $agent->name;

returns User-Agent name like 'DoCoMo'.

=item is_mobile

  if ($agent->is_mobile) {
      # it's really a mobile agent
  }

returns if the agent is mobile or not.

=item is_docomo, is_j_phone, is_ezweb

returns if the agent is DoCoMo or J-Phone or EZWeb.

=back

=head1 WARNINGS

Following warnings might be raised when C<$^W> is on.

=over 4

=item "%s: no match. Might be new variants. please contact the author of HTTP::MobileAgent!"

User-Agent: string does not match patterns provided in subclasses. It
may be faked user-agent or a new variant. Feel free to mail me to
inform this.

=back

=head1 NOTE

=over 4

=item "Why not adding this module as an extension of HTTP::BrowserDetect?"

Yep, I tried to do. But the module's code seems hard enough for me to
extend and don't want to bother the author for this mobile-specific
features. So I made this module as a separated one.

=back

=head1 MORE IMPLEMENTATIONS

If you have any idea / request for this module to add new subclass,
I'm open to the discussion or (more preferable) patches. Feel free to
mail me.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::MobileAgent::DoCoMo>, L<HTTP::MobileAgent::JPhone>,
L<HTTP::MobileAgent::EZweb>, L<HTTP::MobileAgent::NonMobile>,
L<HTTP::BrowserDetect>

Reference URL for specification is listed in Pods for each subclass.

=cut
