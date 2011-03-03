use warnings;
use strict;
use Test::More tests => 2;
use Test::TCP;
use t::Server;

# ABOUT: some tcp server related software returns control when received SIGTERM instead of exit.
# This test emulate it's situation.

test_tcp(
    client => sub {
        ok 1;
        # nop... but after this statement, Test::TCP send SIGTERM to server process.
    },
    server => sub {
        my $port = shift;
        my $sock = new_sock($port);
        my $term_received = 0;
        $SIG{TERM} = sub { $term_received++ };
        while ($term_received == 0) {
            my $csock = $sock->accept;
            if ($csock) {
                $csock->close();
            }
        }
    },
);

ok 1, 'test finished.';
