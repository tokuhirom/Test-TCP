use warnings;
use strict;
use Test::More;
use Test::TCP;
use Test::Requires;

# ABOUT: some tcp server related software returns control when received SIGTERM

test_tcp(
    client => sub {
        ok 1;
        # nop
    },
    server => sub {
        my $port = shift;
        my $sock = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Timeout   => 0.1,
            Listen    => 5,
        ) or die $!;
        my $i = 0;
        $SIG{TERM} = sub { $i++ };
        while ($i == 0) {
            my $csock = $sock->accept;
            if ($csock) {
                $csock->close();
            }
        }
    },
);
done_testing;

