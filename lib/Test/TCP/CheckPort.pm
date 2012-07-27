package Test::TCP::CheckPort;
use strict;
use warnings;
use base qw/Exporter/;
use IO::Socket::INET;

our @EXPORT = qw/ check_port shell_check_port /;

sub shell_check_port { print check_port( @ARGV ) }

sub check_port {
    my ( $port ) = @_;

    my $remote = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
    );
    if ( $remote ) {
        close $remote;
        return 1;
    }
    else {
        return 0;
    }
}

1;
