use strict;
use warnings;
use utf8;
use Test::More;
use Test::TCP;

my ($port, $sleep, $retry);
{
    no warnings 'redefine';
    *Net::EmptyPort::wait_port = sub {
        ($port, $sleep, $retry) = @_;
        1;
    };
}

# Test::TCP::wait_port arguments are passed to Net::EmptyPort::wait_port.
{
    Test::TCP::wait_port(1, 0.00001, 3);
    is($sleep, 0.00001);
    is($retry, 3);
}

# Test::TCP#new arguments are passed to Net::EmptyPort::wait_port.
{
    my $tcp = Test::TCP->new(
        code => sub { },
        wait_port_retry => 4,
        wait_port_sleep => 0.00008,
    );
    is($sleep, 0.00008);
    is($retry, 4);
}

# test_tcp() arguments are passed to Net::EmptyPort::wait_port.
{
    test_tcp(
        client => sub {
        },
        server => sub {
        },
        wait_port_retry => 2,
        wait_port_sleep => 0.00009,
    );
    is($sleep, 0.00009);
    is($retry, 2);
}

done_testing;

