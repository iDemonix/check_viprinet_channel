#!/usr/bin/perl -w

# check_viprinet_channel.pl v0.1.0
# checks the operational status of a supplied channel ID (against hub, not client)

# author	Dan Walker <dan@danwalker.com>
# created	2015-02-13

use strict 'vars';
use Net::SNMP qw(ticks_to_time);;
use Getopt::Std;

my $script_name     = 'check_viprinet_channel.pl';
my $script_version  = '0.1.0';

# Command arguments

# H = hostname
# C = community
# p = port (SNMP)
# t = timeout
# c = channel

my %options=();
getopts("H:C:p:t:c:", \%options);

my $help_info = <<END;
\n$script_name - v$script_version
Check operational status of a Viprinet channel, from the hub end

Usage:
 -H\tAddress of hostname of Viprinet hub
 -C\tSNMP community string
 -p\tSNMP port (optional, defaults to port 161)
 -t\tConnection timeout (optional, default 30s)
 -c\tChannel - the channel ID to check the operational status of

Example:
 $script_name -H vmh1.rack1.place -C public -c 301
END

# check OIDs
my $oid_name            = ".1.3.6.1.4.1.35424.1.6.2.1.2"; # name of the channel
my $oid_status          = ".1.3.6.1.4.1.35424.1.6.2.1.4"; # operational status

# exit codes
my $exit_ok             = 0;
my $exit_warning        = 1;
my $exit_critical       = 2;
my $exit_unknown        = 3;

# options
my $opt_host    = $options{H};
my $opt_comm    = $options{C};
my $opt_port    = $options{p} || 161;
my $opt_time    = $options{t} || 30;
my $opt_chan    = $options{c};

# op status codes
my $status_codes = {
        0       => "Disconnected",
        1       => "Connected",
        2       => "Connecting",
        3       => "Disconnecting",
        4       => "Connection ping test wait",
        5       => "Connection too slow",
        6       => "Connection stalled",
        7       => "Error",
        8       => "Disconnecting",
        };

# SNMP vars
my $session;
my $error;

# check for arguments
if(!defined $options{H} || !defined $options{C} || !defined $options{c} ){
        print "$help_info\nNot all required options were specified.\n\n";
        exit $exit_unknown;
}

# setup the SNMP session
($session, $error) = Net::SNMP->session(
                -hostname       => $opt_host,
                -community      => $opt_comm,
                -timeout        => $opt_time,
                -port           => $opt_port,
                -translate      => [-timeticks => 0x0],
                );

if (!defined $session) {
      print "Whoops: Failed to establish an SNMP session\n";
          exit $exit_critical;
}

my $chan_name = query_oid($oid_name.'.'.$opt_chan);
my $chan_status = query_oid($oid_status.'.'.$opt_chan);

if ( $chan_status eq 1 ) {
        print "OK - Channel '$chan_name' has status: $status_codes->{$chan_status}\n";
        exit($exit_ok);
} elsif ( $chan_status eq 0 || ( $chan_status > 1 && $chan_status < 9 ) ) {
        print "Critical - Channel '$chan_name' has status: $status_codes->{$chan_status}\n";
        exit($exit_critical);
} else {
		print "Unknown - Channel '$chan_name' has status: $status_codes->{$chan_status}\n";
		exit($exit_unknown);
}

sub query_oid {
# this function will poll the active SNMP session and return the value
# of the OID specified. Only inputs are OID. Will use global $session
# variable for the session.
        my $oid = $_[0];
        my $response = $session->get_request(-varbindlist => [ $oid ],);

        # if there was a problem querying the OID error out and exit
        if (!defined $response) {
                $session->close();
                print "Unknown: Can't get SNMP result\n";
                exit $exit_unknown;
        }
        return $response->{$oid};
}