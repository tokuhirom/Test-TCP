use warnings;
use strict;
use Test::More tests => 9;
use Test::TCP;
use IO::Socket::INET;
use t::Server;

my $child_pid;
eval {
    test_tcp(
        client => sub {
            my ($port, $pid) = @_;
            $child_pid = $pid;
            sleep 3; # wait till the server actually starts
            die "sinamon";
        },
        server => sub {
            my $port = shift;
            t::Server->new('127.0.0.1', $port)->run(sub { });
        },
    );
};
my $e = $@;
ok $e;
like $e, qr/sinamon/;
my $killed = kill 9, $child_pid;
is $killed, 0, "already killed by test_tcp";

if ($?) {
    # It's maybe ActivePerl's bug.
    # http://ppm4.activestate.com/MSWin32-x86/5.12/1200/T/TO/TOKUHIROM/Test-TCP-1.11.d/log-20101221T221845.txt
    diag "test_tcp() leaks \$?. Maybe it's Perl bug?: $?";
    $? = 0;
}

eval { test_tcp (); };
$e = $@;
ok ($e, 'No client is fatal error');
like ($e, qr/missing mandatory parameter client/, 'No client is fatal error');

eval { test_tcp (client => 1); };
$e = $@;
ok ($e, 'No server is fatal error');
like ($e, qr/missing mandatory parameter server/, 'No server is fatal error');

eval { Test::TCP->new (); };
$e = $@;
ok ($e, 'No code is fatal error');
like ($e, qr/missing mandatory parameter 'code'/, 'No code is fatal error');
