use warnings;
use strict;
use Test::More tests => 11;
use Net::EmptyPort qw(empty_port check_port);
use IO::Socket::INET;

my ($port, $new_port, $sock);

foreach my $proto_uc ('TCP', 'UDP') {
    my $proto = lc $proto_uc;
    $port = empty_port(5000, $proto);
    ok( $port, $proto_uc.': port found via empty_port' );

    $sock = new_ok( 'IO::Socket::INET' => [
        (($proto eq 'udp') ? () : (Listen => 5)),
        LocalAddr => '127.0.0.1',
        LocalPort => $port,
        Proto     => $proto,
        (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
    ] );

    $new_port = empty_port($port, $proto);
    isnt( $new_port, $port, $proto_uc.': different port found via empty_port' );

    $sock->close;
    $sock = new_ok( 'IO::Socket::INET' => [
        (($proto eq 'udp') ? () : (Listen => 5)),
        LocalAddr => '127.0.0.1',
        LocalPort => $port,
        PeerAddr  => '127.0.0.1',
        PeerPort  => $new_port,
        Proto     => $proto,
        (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
    ] );

    is( check_port($port)    , 0, $proto_uc.': check_port($port)     == 0') if ($proto eq 'udp');
    is( check_port($new_port), 0, $proto_uc.': check_port($new_port) == 0');

    $sock->close;
}

1;
