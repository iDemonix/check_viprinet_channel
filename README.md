# check_viprinet_channel

This Nagios/Icinga plugin checks the operational status of a supplied channel against a Viprinet hub.

The check works by using the *Net::SNMP* library, which is a requirement. The script also only supports the v2c implementation of SNMP, although v3 support could be added if anyone needs it. 

## Example Usage

	[dwalker@dan01 ~]$ perl check_viprinet_channel.pl -H 10.0.0.1 -C public -c 1	OK - Channel '1' has status: Connected
	
	[dwalker@dan01 ~]$ perl check_viprinet_channel.pl -H 10.0.0.1 -C public -c 2	OK - Channel '2' has status: Connection stalled
	
## Arguments

	-H hostname 		Address of the Viprinet Hub
	-C community		SNMP community (v2c)
	-t channel			Channel ID
	-t timeout			Timeout for SNMP
	-p port				SNMP port

## Issues and Requests

If anyone finds a bug or would like to request a new feature, please do so via GitHub.