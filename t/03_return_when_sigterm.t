use warnings;
use strict;
use Test::More;
use Test::TCP;
use t::Server;

# ABOUT: some tcp server related software returns control when received SIGTERM

test_tcp(
    client => sub {
        ok 1;
        # nop
    },
    server => sub {
        my $port = shift;
        my $sock = new_sock($port);
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

