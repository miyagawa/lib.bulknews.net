package MT::Plugin::Emoticon;

use strict;
use Text::Emoticon::MSN;
our $VERSION = "1.00";

our %EmoticonOpts = (
    imgbase => "http://messenger.msn.com/Resource/emoticons",
);

MT::Template::Context->add_global_filter(emoticon => \&emoticon);

sub emoticon {
    my $content = shift;
    my $emoticon = Text::Emoticon::MSN->new(%EmoticonOpts);
    return return $emoticon->filter($content);
}

1;
