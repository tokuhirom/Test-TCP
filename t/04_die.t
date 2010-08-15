use warnings;
use strict;
use Test::More tests => 3;
use Test::TCP;
use IO::Socket::INET;
use t::Server;

my $child_pid;
eval {
    test_tcp(
        client => sub {
            my ($port, $pid) = @_;
            $child_pid = $pid;
            sleep 3; # wait till the server actually starts
            die "sinamon";
        },
        server => sub {
            my $port = shift;
            t::Server->new($port)->run(sub { });
        },
    );
};
ok $@;
like $@, qr/sinamon/;
my $killed = kill 9, $child_pid;
is $killed, 0, "already killed by test_tcp";

