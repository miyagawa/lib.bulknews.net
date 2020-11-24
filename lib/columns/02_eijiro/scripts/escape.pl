#!/usr/local/bin/perl

use strict;
use URI::Escape;

my $query = 'エスケープ=escape';
print uri_escape($query, '\W');
