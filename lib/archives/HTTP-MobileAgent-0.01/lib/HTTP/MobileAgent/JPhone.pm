package HTTP::MobileAgent::JPhone;

use strict;
use base qw(HTTP::MobileAgent);

__PACKAGE__->make_accessors(
    qw(name version model packet_compliant
       serial_number vendor vendor_version java_info)
);

sub parse {
    my $self = shift;
    my($main, @rest) = split / /, $self->user_agent;

    if (@rest) {
	# J-PHONE/4.0/J-SH51/SNJSHA3029293 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
	$self->{packet_compliant} = 1;
	@{$self}{qw(name version model serial_number)} = split m!/!, $main;
	if ($self->{serial_number}) {
	    $self->{serial_number} =~ s/^SN// or return $self->no_match;
	}

	my $vendor = shift @rest;
	@{$self}{qw(vendor vendor_version)} = split m!/!, $vendor;

	my %java_info = map split(m!/!), @rest;
	$self->{java_info} = \%java_info;
    }
    else {
	# J-PHONE/2.0/J-DN02
	@{$self}{qw(name version model)} = split m!/!, $main;
	$self->{vendor} = ($self->{model} =~ /J-([A-Z]+)/)[0] if $self->{model};
    }
}

sub is_j_phone { 1 }

1;
__END__

=head1 NAME

HTTP::MobileAgent::JPhone - J-Phone implementation

=head1 SYNOPSIS

  use HTTP::MobileAgent;

  local $ENV{HTTP_USER_AGENT} = "J-PHONE/2.0/J-DN02";
  my $agent = HTTP::MobileAgent->new;

  printf "Name: %s\n", $agent->name;		# "J-PHONE"
  printf "Version: %s\n", $agent->version;	# 2.0
  printf "Model: %s\n", $agent->model;		# "J-DN02"
  print  "Packet is compliant.\n" if $agent->packet_compliant; # false

  # only availabe in Java compliant
  # e.g.) "J-PHONE/4.0/J-SH51/SNXXXXXXXXX SH/0001a Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0"
  printf "Serial: %s\n", $agent->serial_number; # XXXXXXXXXX
  printf "Vendor: %s\n", $agent->vendor;        # 'SH'
  printf "Vender Version: %s\n", $agent->vendor_version; # "0001a"

  my $info = $self->java_info;		# hash reference
  print map { "$_: $info->{$_}\n" } keys %$info;

=head1 DESCRIPTION

HTTP::MobileAgent::JPhone is a subclass of HTTP::MobileAgent, which
implements J-PHONE user agents.

=head1 METHODS

See L<HTTP::MobileAgent/"METHODS"> for common methods. Here are
HTTP::MobileAgent::JPhone specific methods.

=over 4

=item version

  $version = $agent->version;

returns J-PHONE version number like '1.0'.

=item model

  $model = $agent->model;

returns name of the model like 'J-DN02'.

=item packet_compliant

  if ($agent->packet_compliant) { }

returns whether the agent is packet connection complicant or not.

=item serial_number

  $serial_number = $agent->serial_number;

return terminal unique serial number. returns undef if user forbids to
send his/her serial number.

=item vendor

  $vendor = $agent->vendor;

returns vendor code like 'SH'.

=item vendor_version

  $vendor_version = $agent->vendor_version;

returns vendor version like '0001a'.  returns undef if unknown,

=item java_info

  $info = $agent->java_info;

returns hash reference of Java profiles. Hash structure is something like:

  'Profile'       => 'MIDP-1.0',
  'Configuration' => 'CLDC-1.0',
  'Ext-Profile'   => 'JSCL-1.1.0',

returns undef if unknown.

=back

=head1 TODO

=over 4

=item *

Parse C<x-jphone-*> headers.

=item *

Area information support on http://www.dp.j-phone.com/jsky/position.html

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::MobileAgent>

http://www.dp.j-phone.com/jsky/user.html

http://www.dp.j-phone.com/jsky/position.html


=cut
