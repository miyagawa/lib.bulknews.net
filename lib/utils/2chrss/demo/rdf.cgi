#!/usr/bin/perl
use strict;
use CGI;

do_task(CGI->new);

sub do_task {
    my $query = shift;
    my $name = $query->path_info;
    $name =~ s,^/,,;
    $name =~ /^\w+$/ or return usage($query);
    my $xml = getxml($name);
    print $query->header('text/xml; charset=utf-8'), $xml;    
}

sub getxml {
    my $name = shift;
    return scalar qx(2chrss --charset=utf-8 $name);
}

sub usage {
    my $query = shift;
    print $query->header, "Usage: /path/to/rdf/unix";
}
