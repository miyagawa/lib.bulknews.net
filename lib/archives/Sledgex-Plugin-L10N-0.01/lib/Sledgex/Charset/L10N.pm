package Sledgex::Charset::L10N;
# $Id: L10N.pm,v 1.1 2002/10/20 14:30:44 miyagawa Exp $
#
# Tatsuhiko Miyagawa <miyagawa@edge.co.jp>
# Livin' On The EDGE, Limited.
#

use strict;
use base qw(Sledge::Charset::Null);

sub charset {
    my $self = shift;
    $self->{charset} = shift if @_;
    $self->{charset};
}

sub content_type {
    my $self = shift;
    my $type = "text/html";
    $type .= "; charset=" . $self->charset if $self->charset;
    return $type;
}


1;
