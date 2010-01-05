use strict;
use warnings;
use Test::TCP;
use Test::More;
use t::Server;

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
        t::Server->new($port1)->run;
    },
);

