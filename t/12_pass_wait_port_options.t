use strict;
use warnings;
use utf8;
use Test::More;
use Test::TCP;

my ($port, $max_wait);
{
    no warnings 'redefine';
    *Net::EmptyPort::wait_port = sub {
        ($port, $max_wait) = @_;
        1;
    };
}

# Test::TCP::wait_port arguments are passed to Net::EmptyPort::wait_port.
{
    Test::TCP::wait_port(1, 1);
    is($max_wait, 1);
}

# Test::TCP#new arguments are passed to Net::EmptyPort::wait_port.
{
    my $tcp = Test::TCP->new(
        code => sub { },
        max_wait => 3,
    );
    is($max_wait, 3);
}

# test_tcp() arguments are passed to Net::EmptyPort::wait_port.
{
    test_tcp(
        client => sub {
        },
        server => sub {
        },
        max_wait => 2,
    );
    is($max_wait, 2);
}

done_testing;

