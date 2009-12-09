#!perl
use warnings;
use strict;
use Test::More tests => 22;
use Test::TCP;
use IO::Socket::INET;
use t::Server;

sleep 1;
test_tcp(
    client => sub {
        my $port = shift;
        ok $port, "test case for sharedfork" for 1..10;
        my $sock = IO::Socket::INET->new(
            PeerPort => $port,
            PeerAddr => '127.0.0.1',
            Proto    => 'tcp'
        ) or die "Cannot open client socket: $!";

        note "send 1";
        print {$sock} "foo\n";
        my $res = <$sock>;
        is $res, "foo 1\n";

        note "send 2";
        print {$sock} "bar\n";
        my $res2 = <$sock>;
        is $res2, "bar 1\n";

        note "finalize";
        print {$sock} "quit\n";
    },
    server => sub {
        my $port = shift;
        diag "sub1.st uses - $port";
        ok $port, "test case for sharedfork" for 1..10;
        t::Server->new($port)->run(sub {
            note "new request";
            my ($remote, $line, $sock) = @_;
            $line =~ s/[\r\n]//g;
            print {$remote} "$line 1\n";
        });
    },
);

