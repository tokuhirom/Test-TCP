use strict;
use warnings;
use Test::More;
use Net::EmptyPort qw(:DEFAULT empty_port_multi);

my @ports = empty_port_multi(count=>3);
is scalar @ports,3, "found three empty ports";
ok(($ports[0] != $ports[1])
       && ($ports[0] != $ports[2])
           && ($ports[1] != $ports[2]),
   'all ports are different');

for my $port (@ports) {
    ok !wait_port( $port, 0.1 ), "port is closed";

    my $sock = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => $port,
        Listen    => 1,
    ) or die "Couldn't create socket: $!";

    ok wait_port( $port, 3 ), "port is open";
}

done_testing;
