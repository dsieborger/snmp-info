# SNMP::Info::Layer2::Catalyst
# Max Baker
#
# Copyright (c) 2002,2003 Regents of the University of California
# Copyright (c) 2003,2004 Max Baker changes from version 0.8 and beyond
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the 
#       names of its contributors may be used to endorse or promote products 
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer2::Catalyst;
$VERSION = 1.0;
# $Id$

use strict;

use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::CiscoVTP;
use SNMP::Info::CiscoStack;
use SNMP::Info::CDP;
use SNMP::Info::CiscoStats;

use vars qw/$VERSION $DEBUG %GLOBALS %MIBS %FUNCS %MUNGE $INIT/ ;
@SNMP::Info::Layer2::Catalyst::ISA = qw/SNMP::Info::Layer2 SNMP::Info::CiscoStack 
                                        SNMP::Info::CiscoVTP SNMP::Info::CDP SNMP::Info::CiscoStats Exporter/;
@SNMP::Info::Layer2::Catalyst::EXPORT_OK = qw//;

%MIBS =    ( %SNMP::Info::Layer2::MIBS, 
             %SNMP::Info::CiscoVTP::MIBS,
             %SNMP::Info::CiscoStack::MIBS,
             %SNMP::Info::CiscoStats::MIBS,
             %SNMP::Info::CDP::MIBS,
           );

%GLOBALS = (
            %SNMP::Info::Layer2::GLOBALS,
            %SNMP::Info::CiscoVTP::GLOBALS,
            %SNMP::Info::CiscoStack::GLOBALS,
            %SNMP::Info::CiscoStats::GLOBALS,
            %SNMP::Info::CDP::GLOBALS,
           );

%FUNCS =   (
            %SNMP::Info::Layer2::FUNCS,
            %SNMP::Info::CiscoVTP::FUNCS,
            %SNMP::Info::CiscoStack::FUNCS,
            %SNMP::Info::CiscoStats::FUNCS,
            %SNMP::Info::CDP::FUNCS,
           );

%MUNGE =   (
            %SNMP::Info::Layer2::MUNGE,
            %SNMP::Info::CiscoVTP::MUNGE,
            %SNMP::Info::CiscoStack::MUNGE,
            %SNMP::Info::CDP::MUNGE,
            %SNMP::Info::CiscoStats::MUNGE,
           );

# Need to specify this or it might grab the ones out of L2 instead of CiscoStack
*SNMP::Info::Layer2::Catalyst::serial         = \&SNMP::Info::CiscoStack::serial;
*SNMP::Info::Layer2::Catalyst::interfaces     = \&SNMP::Info::CiscoStack::interfaces;
*SNMP::Info::Layer2::Catalyst::i_duplex       = \&SNMP::Info::CiscoStack::i_duplex;
*SNMP::Info::Layer2::Catalyst::i_type         = \&SNMP::Info::CiscoStack::i_type;
*SNMP::Info::Layer2::Catalyst::i_name         = \&SNMP::Info::CiscoStack::i_name;
*SNMP::Info::Layer2::Catalyst::i_duplex_admin = \&SNMP::Info::CiscoStack::i_duplex_admin;

# Overidden Methods

# i_physical sets a hash entry as true if the iid is a physical port
sub i_physical {
    my $cat = shift;

    my $p_port = $cat->p_port();

    my %i_physical;
    foreach my $port (keys %$p_port) {
        my $iid = $p_port->{$port};
        $i_physical{$iid} = 1;  
    }
    return \%i_physical;
}

sub vendor {
    return 'cisco';
}

sub os {
    return 'catalyst';
}

sub os_ver {
    my $cat = shift;
    my $os_ver = $cat->SUPER::os_ver();
    return $os_ver if defined $os_ver;

    my $m_swver = $cat->m_swver();
    return undef unless defined $m_swver;

    # assume .1 entry is the chassis and the sw version we want.
    return $m_swver->{1} if defined $m_swver->{1};
    return undef;
}

# Workaround for incomplete bp_index
sub bp_index {
   my $cat = shift;
    my $p_index = $cat->p_port();
    my $b_index = $cat->p_oidx();

    my %bp_index;
    foreach my $iid (keys %$p_index){
        my $ifidx = $p_index->{$iid};
        next unless defined $ifidx;
        my $bpidx = $b_index->{$iid}||0;

        $bp_index{$bpidx} = $ifidx;
    }
    return \%bp_index;
}

sub cisco_comm_indexing {
    1;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::Catalyst - Perl5 Interface to Cisco Catalyst devices running Catalyst OS.

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $cat = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $cat->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info subclass to provide information for Cisco Catalyst series switches running CatOS.

This class includes the Catalyst 2920, 4000, 5000, 6000 (hybrid mode) families.

This subclass is not for all devices that have the name Catalyst.  Note that some Catalyst
switches run IOS, like the 2900 and 3550 families.  Cisco Catalyst 1900 switches use their
own MIB and have a separate subclass.  Use the method above to have SNMP::Info determine the
appropriate subclass before using this class directly.

See SNMP::Info::device_type() for specifics.

Note:  Some older Catalyst switches will only talk SNMP version 1.  Some newer ones will not
return all their data if connected via Version 1.

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above. 

 my $cat = new SNMP::Info::Layer2::Catalyst(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=item SNMP::Info::CiscoVTP

=item SNMP::Info::CiscoStack

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See SNMP::Info::Layer2 for its own MIB requirements.

See SNMP::Info::CiscoVTP for its own MIB requirements.

See SNMP::Info::CiscoStack for its own MIB requirements.

=back

These MIBs are found in the standard v2 MIBs from Cisco.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $cat->os()

Returns 'catalyst'

=item $cat->os_ver()

Tries to use the value from SNMP::Info::CiscoStats->os_ver() and if it fails 
it grabs $cat->m_swver()->{1} and uses that.

=item $cat->vendor()

Returns 'cisco'

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in SNMP::Info::Layer2 for details.

=head2 Global Methods imported from SNMP::Info::CiscoVTP

See documentation in SNMP::Info::CiscoVTP for details.

=head2 Global Methods imported from SNMP::Info::CiscoStack

See documentation in SNMP::Info::CiscoStack for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $cat->bp_index()

Returns reference to hash of bridge port table entries map back to interface identifier (iid)

Crosses (B<portCrossIndex>) to (B<portIfIndex>) since some devices seem to have
problems with BRIDGE-MIB

=back

=head2 Table Methods imported from SNMP::Info::CiscoVTP

See documentation in SNMP::Info::CiscoVTP for details.

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in SNMP::Info::Layer2 for details.

=head2 Table Methods imported from SNMP::Info::Layer2::CiscoStack

See documentation in SNMP::Info::Layer2::CiscoStack for details.

=cut
