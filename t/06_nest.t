use strict;
use warnings;
use Test::TCP;
use IO::Socket::INET;
use POSIX;
use Test::More;
use t::Server;
use HTTP::Daemon;

test_tcp(
    client => sub {
        my $port1 = shift;
        test_tcp(
            client => sub {
                my $port2 = shift;
                isnt $port1, $port2, "$port1, $port2";
                done_testing;
            },
            server => sub {
                my $port2 = shift;
                t::Server->new($port2)->run;
            },
        );
    },
    server => sub {
        my $port1 = shift;
#       my $d = HTTP::Daemon->new(ReuseAddr => 1, LocalPort => $port1) || die;
#       while (my $c = $d->accept) {
#           $c->close;
#           undef($c);
#       }
        t::Server->new($port1)->run;
    },
);

