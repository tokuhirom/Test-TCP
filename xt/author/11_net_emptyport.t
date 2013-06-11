use warnings;
use strict;
use Test::More tests => 11;
use Net::EmptyPort qw(empty_port check_port);

our $io_socket_module_name;
BEGIN {
  if (eval { require IO::Socket::IP }) {
    $io_socket_module_name = 'IO::Socket::IP';
  } elsif (eval { require IO::Socket::INET6 }) {
    $io_socket_module_name = 'IO::Socket::INET6';
  } elsif (eval { require IO::Socket::INET }) {
    $io_socket_module_name = 'IO::Socket::INET';
  }
}

# This UDP test case does not portable if there is DNS cache server.

my ($port, $new_port, $sock);

foreach my $proto_uc ('TCP', 'UDP') {
    my $proto = lc $proto_uc;
    $port = empty_port(5000, $proto);
    ok( $port, $proto_uc.': port found via empty_port' );

    diag "Port: $port - $proto";

    $sock = new_ok( $io_socket_module_name => [
        (($proto eq 'udp') ? () : (Listen => 5)),
        LocalAddr => 'localhost',
        LocalPort => $port,
        Proto     => $proto,
        (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
    ] );

    $new_port = empty_port($port, $proto);
    isnt( $new_port, $port, $proto_uc.': different port found via empty_port' );
    diag "New port: $new_port - $proto";

    $sock->close;
    $sock = new_ok( $io_socket_module_name => [
        (($proto eq 'udp') ? () : (Listen => 5)),
        LocalAddr => 'localhost',
        LocalPort => $port,
      # PeerAddr  => 'localhost',
      # PeerPort  => $new_port,
        Proto     => $proto,
        (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
    ] );

    is( check_port($port)    , 0, $proto_uc.': check_port($port)     == 0') if ($proto eq 'udp');
    is( check_port($new_port), 0, $proto_uc.': check_port($new_port) == 0');

    $sock->close;
}

1;
