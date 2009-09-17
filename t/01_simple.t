use warnings;
use strict;
use Test::More tests => 22;
use Test::TCP;
use IO::Socket::INET;
use t::Server;

test_tcp(
    client => sub {
        my $port = shift;
        ok $port for 1..10;
        my $sock = IO::Socket::INET->new(
            PeerPort => $port,
            PeerAddr => '127.0.0.1',
            Proto    => 'tcp'
        ) or die "Cannot open client socket: $!";
        print {$sock} "foo\n";
        my $res = <$sock>;
        is $res, "foo\n";
        print {$sock} "bar\n";
        my $res2 = <$sock>;
        is $res2, "bar\n";
        print {$sock} "quit\n";
    },
    server => sub {
        my $port = shift;
        ok $port for 1..10;
        t::Server->new($port)->run(sub {
            my ($remote, $line, $sock) = @_;
            print {$remote} $line;
        });
    },
);

