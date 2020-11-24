package Plagger::Plugin::Filter::TracTicketTitle;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    my $entry = $args->{entry};
    if ($entry->link =~ m!/ticket/\d+! && $entry->title =~ /^Ticket \#\d+ .* created by .*/) {
        $entry->title( $entry->title . ': ' . $entry->body );
    }
}

1;
