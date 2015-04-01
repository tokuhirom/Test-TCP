use strict;
use warnings;
use Test::TCP;
use Test::More tests => 1;
use t::Server;

test_tcp(
    client => sub {
        my $port1 = shift;
        test_tcp(
            client => sub {
                my $port2 = shift;
                isnt $port1, $port2, "$port1, $port2";
            },
            server => sub {
                my $port2 = shift;
                t::Server->new('127.0.0.1', $port2)->run;
            },
        );
    },
    server => sub {
        my $port1 = shift;
        t::Server->new('127.0.0.1', $port1)->run;
    },
);

if ($?) {
    diag "test_tcp() leaks \$?. Maybe it's Perl bug?: $?";
    $? = 0;
}
