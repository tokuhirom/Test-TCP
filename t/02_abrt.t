use strict;
use warnings;
use Test::TCP;
use Test::More;
use Socket;
use IO::Socket::INET;
use t::Server;

plan skip_all => "win32 doesn't support embedded function named dump()" if $^O eq 'MSWin32';
plan tests => 2;

test_tcp(
    client => sub {
        my $port = shift;
        my $sock = IO::Socket::INET->new(
            PeerPort => $port,
            PeerAddr => '127.0.0.1',
            Proto    => 'tcp'
        ) or die "Cannot open client socket: $!";
        print {$sock} "dump\n";
        my $res = <$sock>;
        is $res, "dump\n";
        $sock->close();
        ok 1;
    },
    server => sub {
        my $port = shift;
        t::Server->new('127.0.0.1', $port)->run(sub {
            my ($remote, $line) = @_;
            print {$remote} $line;
            if ($line =~ /dump/) {
                return CORE::dump()
            }
        });
    },
);
