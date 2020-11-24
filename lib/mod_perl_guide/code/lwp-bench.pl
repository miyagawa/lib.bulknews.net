#!/usr/bin/perl -w

use LWP::Parallel::UserAgent;
use Time::HiRes qw(gettimeofday tv_interval);
use strict;

###
# Configuration
###

my $nof_parallel_connections = 10; 
my $nof_requests_total = 100; 
my $timeout = 10;
my @urls = (
	    'http://www.example.com:81/perl/faq_manager/faq_manager.pl',
	    'http://www.example.com:81/perl/access/access.cgi',
	   );


##################################################
# Derived Class for latency timing
##################################################

package MyParallelAgent;
@MyParallelAgent::ISA = qw(LWP::Parallel::UserAgent);
use strict;

###
# Is called when connection is opened
###
sub on_connect {
  my ($self, $request, $response, $entry) = @_;
  $self->{__start_times}->{$entry} = [Time::HiRes::gettimeofday];
}

###
# Are called when connection is closed
###
sub on_return {
  my ($self, $request, $response, $entry) = @_;
  my $start = $self->{__start_times}->{$entry};
  $self->{__latency_total} += Time::HiRes::tv_interval($start);
}

sub on_failure {
  on_return(@_);  # Same procedure
}

###
# Access function for new instance var
###
sub get_latency_total {
  return shift->{__latency_total};
}

##################################################
package main;
##################################################
###
# Init parallel user agent
###
my $ua = MyParallelAgent->new();
$ua->agent("pounder/1.0");
$ua->max_req($nof_parallel_connections);
$ua->redirect(0);    # No redirects

###
# Register all requests
###
foreach (1..$nof_requests_total) {
  foreach my $url (@urls) {
    my $request = HTTP::Request->new('GET', $url);
    $ua->register($request);
  }
}

###
# Launch processes and check time
###
my $start_time = [gettimeofday];
my $results = $ua->wait($timeout);
my $total_time = tv_interval($start_time);

###
# Requests all done, check results
###

my $succeeded     = 0;
my %errors = ();

foreach my $entry (values %$results) {
  my $response = $entry->response();
  if($response->is_success()) {
    $succeeded++; # Another satisfied customer
  } else {
    # Error, save the message
    $response->message("TIMEOUT") unless $response->code();
    $errors{$response->message}++;
  }
}

###
# Format errors if any from %errors 
###
my $errors = join(',', map "$_ ($errors{$_})", keys %errors);
$errors = "NONE" unless $errors;

###
# Format results
###

#@urls = map {($_,".")} @urls;
my @P = (
      "URL(s)"          => join("\n\t\t ", @urls),
      "Total Requests"  => "$nof_requests_total",
      "Parallel Agents" => $nof_parallel_connections,
      "Succeeded"       => sprintf("$succeeded (%.2f%%)\n",
				   $succeeded * 100 / $nof_requests_total),
      "Errors"          => $errors,
      "Total Time"      => sprintf("%.2f secs\n", $total_time),
      "Throughput"      => sprintf("%.2f Requests/sec\n", 
				   $nof_requests_total / $total_time),
      "Latency"         => sprintf("%.2f secs/Request", 
				   ($ua->get_latency_total() || 0) / 
				   $nof_requests_total),
     );

my ($left, $right);
###
# Print out statistics
###
format STDOUT =
@<<<<<<<<<<<<<<< @*
"$left:",        $right
.

while(($left, $right) = splice(@P, 0, 2)) {
  write;
}
