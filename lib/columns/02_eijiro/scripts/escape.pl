#!/usr/local/bin/perl

use strict;
use URI::Escape;

my $query = '����������=escape';
print uri_escape($query, '\W');
