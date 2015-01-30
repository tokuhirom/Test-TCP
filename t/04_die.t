use warnings;
use strict;
use Config;
use Test::More;
use Test::TCP;
use IO::Socket::INET;
use t::Server;

plan skip_all => "fork not supported on this platform"
  unless $Config::Config{d_fork} || $Config::Config{d_pseudofork} ||
    (($^O eq 'MSWin32' || $^O eq 'NetWare') and
     $Config::Config{useithreads} and
     $Config::Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

plan tests => 3;

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
            t::Server->new($port)->run(sub { });
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

