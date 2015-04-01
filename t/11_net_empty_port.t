use strict;
use warnings;
use IO::Socket::IP;
use Test::More;
use Net::EmptyPort;

sub doit {
    my ($host, $port) = @_;
    ok !wait_port({ host => $host, port => $port, max_wait => 0.1 }), "port is closed";

    my $sock = IO::Socket::IP->new(
        LocalAddr => $host,
        LocalPort => $port,
        Listen    => 1,
        V6Only    => 1,
    ) or die "Couldn't create socket: $!";

    ok wait_port({ host => $host, port => $port, max_wait => 3 }), "port is open";
};

subtest 'v4' => sub {
    my $port = empty_port();
    ok "found an empty port";
    doit('127.0.0.1', $port);
};

subtest 'v6' => sub {
    my $port = do {
        local $@;
        my $p = eval {
            empty_port({ host => '::1' });
        };
        plan skip_all => "IPv6 not supported"
            if $@;
        $p;
    };
    ok "found an empty port";
    doit('::1', $port);
};

done_testing;
