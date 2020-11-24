# rss2audiobook: convert RSS feed into iPod/iTunes Audiobook
use strict;
use warnings;
use Encode;
use File::Basename;
use File::Spec;
use Time::HiRes qw(sleep);
use LWP::Simple;
use HTML::Entities;
use Win32::OLE;
use Win32::SAPI5;
use XML::RSS;

our $VoiceName = "Microsoft Mike";

my $me = basename($0);
my $url = shift or die "Usage: $me <URL of RSS>\n";
my $wav = "rss2audiobook-$$.wav";

my $rss = record_rss($url => $wav);
encode_AAC($wav, $rss);

sub record_rss {
    my($url, $wav) = @_;

    # setup RSS parser
    my $rss = XML::RSS->new();
    $rss->add_module(
	prefix => 'content',
	uri => 'http://purl.org/rss/1.0/modules/content/',
    );

    # fetch RSS, parse it
    my $xml = get($url);
    $rss->parse($xml);

    # setup Microsoft Speech API
    my $stream = Win32::SAPI5::SpFileStream->new();
    $stream->Open($wav, 3, 0);	# 3 = SSFMCreateForWrite

    my $voice = Win32::SAPI5::SpVoice->new();
    $voice->SetProperty(AudioOutputStream => $stream->{_object}); # XXX _object?
    set_voice($voice, $VoiceName);

    speak($voice, "Here are entries of $rss->{channel}->{title}");

    for my $item (@{$rss->items}) {
	speak($voice, "$item->{title}");
	speak($voice, make_content($item));
    }

    # we've done recording
    $stream->Close();

    return $rss;
}

sub set_voice {
    my($voice, $name) = @_;
    my $tokens = $voice->GetVoices;
    for (my $i = 0; $i < $tokens->Count; $i++) {
	if ($name eq ($tokens->Item($i)->GetDescription||$tokens->Item($i)->GetAttribute('Name'))) {
	    return $voice->SetProperty(Voice => $tokens->Item($i));
	}
    }
}

sub speak {
    my($voice, $msg) = @_;
    print "$msg\n";
    $voice->speak($msg);
}

sub make_content {
    my $item = shift;
    if ($item->{content}->{encoded}) {
	return decode_html($item->{content}->{encoded});
    } elsif ($item->{description}) {
	return decode_html($item->{description});
    } else {
	return "";
    }
}

sub decode_html {
    my $html = shift;
    $html =~ s/<.*?>//g;
    return HTML::Entities::decode($html);
}

sub encode_AAC {
    my($wav, $rss) = @_;

    # setup iTunes AAC encoder
    my $itunes  = Win32::OLE->new("iTunes.Application");
    my $enc = $itunes->Encoders->ItemByName("AAC Encoder");
    $itunes->CurrentEncoder($enc); # XXX this raises warning, why?

    # now convert WAV file into AAC
    my $abspath = File::Spec->rel2abs($wav);
    my $status = $itunes->ConvertFile($abspath);
    sleep 0.1 while $status->InProgress;

    # m4a -> m4b: Audiobook
    # remove old track
    my $track = $status->Tracks->Item(1);
    my $from  = $track->Location();
    $track->Delete(); unlink $wav;
    (my $to = $from) =~ s/\.m4a$/.m4b/;
    rename $from => $to;

    # Add m4b track and edit track information
    $status = $itunes->LibraryPlaylist->AddFile($to);
    sleep 0.1 while $status->InProgress;
    $track = $status->Tracks->Item(1);

    # XXX This doesn't work
    $track->Name(encode("utf-8", $rss->{channel}->{title}));
    $track->Artist(encode("utf-8", ($rss->{channel}->{dc}->{author} || $rss->{channel}->{link})));
}
