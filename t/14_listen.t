use warnings;
use strict;
use Test::More;
use Test::TCP;
use Test::SharedFork;
use IO::Socket::IP;

test_tcp(
    client => sub {
        my ($port, $pid) = @_;
        ok $port, 'got port';
        ok my $sock = IO::Socket::IP->new(
            PeerPort => $port,
            PeerHost => '127.0.0.1',
            Proto    => 'tcp',
            V6Only   => 1,
        ), 'connected' or die "Cannot open client socket: $!";

        ok($sock->print("foo\n"), "send 1");
        is(<$sock>, "foo\n", "recv 1");
    },
    server => sub {
        my ($sock) = @_;
        while (my $remote = $sock->accept) {
            note "new request";
            $remote->print(scalar <$remote>);
        }
    },
    listen => 1,
);

done_testing;
