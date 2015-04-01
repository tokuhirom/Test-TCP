use strict;
use warnings;
use Test::More;
use Net::EmptyPort;

my $port = empty_port;
ok $port, "found an empty port";
ok !wait_port( $port, 0.1 ), "port is closed";

my $sock = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => $port,
    Listen    => 1,
) or die "Couldn't create socket: $!";

ok wait_port( $port, 3 ), "port is open";

done_testing;
