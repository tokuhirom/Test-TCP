use strict;
use warnings;
use IO::Socket::IP;
use Test::More;
use Net::EmptyPort;

sub doit {
    my $host = shift;

    my $port = empty_port();
    ok "found an empty port";

    ok !wait_port({ host => $host, port => $port, max_wait => 0.1 }), "port is closed";

    my $sock = IO::Socket::IP->new(
        LocalAddr => $host,
        LocalPort => $port,
        Listen    => 1,
        V6Only    => 1,
    ) or die "Couldn't create socket: $!";

    ok wait_port({ host => $host, port => $port, max_wait => 3 }), "port is open";
};

ok can_bind('127.0.0.1'), 'bind to 127.0.0.1';
ok ! can_bind('8.8.8.8'), 'bind to an anvailable address';

subtest 'v4' => sub {
    doit('127.0.0.1');
};

subtest 'v6' => sub {
    plan skip_all => "IPv6 not supported"
        unless eval { Socket::IPV6_V6ONLY } and can_bind("::1");
    ok "found an empty port";
    doit('::1');
};

subtest 'return value' => sub {
    my $sock = IO::Socket::IP->new(
        LocalAddr => '127.0.0.1',
        LocalPort => empty_port(),
        Listen    => 1,
    );
    ok $sock;
};

done_testing;
