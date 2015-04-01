use strict;
use warnings;
use utf8;
use Test::More;
use Test::TCP;
use IO::Socket::INET;
use t::Server;

my %wait_port_args;
my $old = \&Net::EmptyPort::wait_port;
my $return = sub { 1 };

{
    no warnings 'redefine';
    *Net::EmptyPort::wait_port = sub {
        %wait_port_args = %{$_[0]};
        $return->(@_);
    };
}

# Test::TCP::wait_port arguments are passed to Net::EmptyPort::wait_port.
{
    Test::TCP::wait_port(1, 1);
    is($wait_port_args{max_wait}, 1);
}

$return = sub { $old->(@_) };

my $server = sub {
    my $port = shift;
    ok $port, "test case for sharedfork" for 1 .. 10;
    t::Server->new('127.0.0.1', $port)->run(sub {
            note "new request";
            my ($remote, $line, $sock) = @_;
            print {$remote} $line;
    });
};

my $client = sub {
    my $port = shift;
    ok $port, "test case for sharedfork" for 1 .. 10;
    my $sock = IO::Socket::INET->new(
        PeerPort => $port,
        PeerAddr => '127.0.0.1',
        Proto    => 'tcp'
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
};

# Test::TCP#new arguments are passed to Net::EmptyPort::wait_port.
{
    my $tcp = Test::TCP->new(
        code => $server,
        max_wait => -3,
    );
    $client->($tcp->port);
    if ($?) {
        # It's maybe ActivePerl's bug.
        # http://ppm4.activestate.com/MSWin32-x86/5.12/1200/T/TO/TOKUHIROM/Test-TCP-1.11.d/log-20101221T221845.txt
        diag "test_tcp() leaks \$?. Maybe it's Perl bug?: $?";
        $? = 0;
    }

    is($wait_port_args{max_wait}, -3);
}

# test_tcp() arguments are passed to Net::EmptyPort::wait_port.
{
    test_tcp(
        client => $client,
        server => $server,
        max_wait => -2,
    );
    is($wait_port_args{max_wait}, -2);
}

done_testing;

