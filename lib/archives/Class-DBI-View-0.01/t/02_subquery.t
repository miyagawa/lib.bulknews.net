use strict;
use Test::More tests => 11;

require_ok 'Class::DBI::View';

use lib 't/lib';
use CD::Music;
use CD::Tester;

CD::Tester->test_all('SubQuery', 'SQLite');
