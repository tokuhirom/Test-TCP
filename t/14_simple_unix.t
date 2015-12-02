use warnings;
use strict;

BEGIN {
    if ($^O =~ m/^(?:qnx|nto|vos|MSWin32)$/ ) {
        print "1..0 # Skip: UNIX domain sockets not implemented on $^O\n";
        exit 0;
    }
};

use Test::More;
use Test::UNIXSock;
use IO::Socket::UNIX;
use t::ServerUNIX;

sub doit {
    ok 1, "starting the test";
    test_unix_sock(
        client => sub {
            my $path = shift;
            ok $path, "test case for sharedfork" for 1..10;
            my $sock = IO::Socket::UNIX->new(
                Peer => $path,
                Type => SOCK_STREAM(),
            ) or die "Cannot open client socket: $!";

            note "send 1";
            print {$sock} "foo\n";
            my $res = <$sock>;
            is $res, "foo\n";

            note "send 2";
            print {$sock} "bar\n";
            my $res2 = <$sock>;
            is $res2, "bar\n";

            note "finalize";
            print {$sock} "quit\n";
        },
        server => sub {
            my $path = shift;
            ok $path, "test case for sharedfork" for 1..10;
            t::ServerUNIX->new($path)->run(sub {
                note "new request";
                my ($remote, $line, $sock) = @_;
                print {$remote} $line;
            });
        },
    );
}

doit();

done_testing;
