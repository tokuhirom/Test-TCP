use strict;
use warnings;
use IO::Socket::IP;
use Test::More;
use Net::EmptyPort;

sub doit {
    my $host = shift;

    my $port = empty_port();
    ok $port, "found an empty port on $host";

    ok !wait_port({ host => $host, port => $port, max_wait => 0.1 }),
        "port $port on $host is closed";

    my $sock = IO::Socket::IP->new(
        LocalAddr => $host,
        LocalPort => $port,
        Listen    => 1,
        V6Only    => 1,
    ) or die "Couldn't create socket: $!";

    ok wait_port({ host => $host, port => $port, max_wait => 3 }),
        "port $port on $host is now open";
};

ok can_bind('127.0.0.1'), 'bind to 127.0.0.1';

# Skip this check if binding to non-local addresses is enabled (most common
# on load balancers with floating IPs)
SKIP: {
    if (-f '/proc/sys/net/ipv4/ip_nonlocal_bind') {
        open my $fh, "<", "/proc/sys/net/ipv4/ip_nonlocal_bind";
        if (<$fh> =~ /1/) {
            skip "Binding to non-local adddresses is allowed";
        } else {
            ok ! can_bind('8.8.8.8'), 'Cannot bind to an unavailable address';
        }
    }
}

subtest 'v4' => sub {
    doit('127.0.0.1');
};

subtest 'v6' => sub {
    plan skip_all => "IPv6 not supported"
        unless eval { Socket::IPV6_V6ONLY } and can_bind("::1");
    diag "found an empty IPv6 port";
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
