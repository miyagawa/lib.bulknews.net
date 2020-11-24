use strict;
use WebService::Bloglines;
use Encode;
use FileHandle;
use File::Spec;
use HTML::Entities;

our $Username  = 'your-account@example.com';
our $Password  = 'your-password';
our $IpodDrive = "D:";         # Drive to mount iPod
our $MarkUnread = 0;           # Mark unread?
our $Encoding   = "Shift_JIS"; # encoding for filesystem and message body

warn "Syncing Bloglines items to your iPod.\n";

my $bloglines = WebService::Bloglines->new(
  username => $Username,
  password => $Password,
);

my $subscription = $bloglines->listsubs();
for my $feed ($subscription->feeds) {
  if ($feed->{BloglinesUnread}) {
    eval {
      warn "Fetching new items for $feed->{htmlUrl}\n";
      fetch_new_item($bloglines, $feed->{BloglinesSubId});
    };
    warn $@ if $@;
  }
}

warn "All done successfuly.\n";

# fetch new item from BloglinesSubId
# then store new items in iPod Notes folder
sub fetch_new_item {
  my($bloglines, $subid) = @_;
  my $update = $bloglines->getitems($subid, $MarkUnread);
  my $feed   = $update->feed();
  for my $item ($update->items) {
    my $filename = construct_filename($feed, $item);
    my $content  = make_content($feed, $item);
    my $fh = FileHandle->new(">$filename") or die "$filename: $!";
    binmode($fh, ":encoding($Encoding)");
    $fh->print($content);
    $fh->close();
  }
}

# creates local filename for iPod Notes folder from URL
sub construct_filename {
  my($feed, $item) = @_;
  return File::Spec->catfile(
    $IpodDrive, "Notes",
    encode($Encoding, normalize_filename("$feed->{title} - $item->{title}")),
  );
}

# normalizes text that can be safely used in iPod FS
sub normalize_filename {
  my $filename = shift;
  $filename =~ s![\\\/:\*\?\"<>\|]!_!g;
  return $filename;
}

# make up text message from $feed and $item
sub make_content {
  my($feed, $item) = @_;

  my $body = $item->{description};
  $body =~ s/<.*?>//g;
  $body = HTML::Entities::decode($body);
  return <<EOF;
Blog: $feed->{title}
Title: $item->{title}
Permalink: $item->{link}

$body
EOF
  ;
}
