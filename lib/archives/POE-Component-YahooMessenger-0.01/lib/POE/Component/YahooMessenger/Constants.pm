package POE::Component::YahooMessenger::Constants;
use strict;

BEGIN {
    use vars qw(@EXPORT @ISA);

    require Exporter;
    @ISA    = qw(Exporter);
    @EXPORT = qw($MessageHeader $BodySeparater
		 $ReceiveEventCodes $ReceiveEventNames
		 $SendEventCodes $SendEventNames
		 $BodyCodes $BodyNames $Default);
}

use vars @EXPORT;

$Default = {
    hostanme      => 'scs.yahoo.com',
    port          => 5050,
};

$MessageHeader = 'YMSG';
$BodySeparater = "\xC0\x80";

$ReceiveEventCodes = {
    1  => 'goes_online',
    2  => 'goes_offline',
    3  => 'change_status',
    4  => 'change_status',
    6  => 'receive_message',
    15 => 'new_friend_alert',
    75 => 'toggle_typing',
    76 => 'server_is_alive',
    84 => 'cram_auth_fail',
    85 => 'receive_buddy_list',
    87 => 'challenge_start',
};

$ReceiveEventNames = { reverse %$ReceiveEventCodes };

$SendEventCodes = {
    %$ReceiveEventCodes,
    6  => 'send_message',
    84 => 'challenge_response',
};

$SendEventNames = { reverse %$SendEventCodes };

$BodyCodes = {
    0  => 'my_id',
    1  => 'id',
    2  => 'login_nickname',
    3  => 'new_buddy_name',
    4  => 'from',
    5  => 'to',
    6  => 'crypt_salt',
    7  => 'buddy_id',
    8  => 'number_of_online_buddies',
    10 => 'status_code',
    11 => 'session_id',
    13 => 'live',
    14 => 'message',
    15 => 'received_time',
    16 => 'error_message',
    19 => 'status_message',
    47 => 'busy_code',
    87 => 'buddy_list',
    94 => 'challenge_string',
    96 => 'crypted_response',
};

$BodyNames = { reverse %$BodyCodes };

1;
