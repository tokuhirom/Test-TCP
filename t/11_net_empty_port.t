use strict;
use warnings;
use Test::More;
use Net::EmptyPort;

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

my $port = empty_port;
ok $port, "found an empty port";
ok !wait_port( $port, 0.1 ), "port is closed";

my $sock = $io_socket_module_name->new(
    LocalAddr => 'localhost',
    LocalPort => $port,
    Listen    => 1,
) or die "Couldn't create socket: $!";

ok wait_port( $port, 3 ), "port is open";

done_testing;
