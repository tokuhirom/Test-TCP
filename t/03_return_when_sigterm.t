use warnings;
use strict;
use Config;
use Test::More;
use Test::TCP;
use t::Server;

plan skip_all => "fork not supported on this platform"
  unless $Config::Config{d_fork} || $Config::Config{d_pseudofork} ||
    (($^O eq 'MSWin32' || $^O eq 'NetWare') and
     $Config::Config{useithreads} and
     $Config::Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

plan tests => 2;

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

        # suppress warnings: [Test::TCP] Child process does not block(PID: 84792, PPID: 84791) 
        # I do it on purpose!
        $SIG{__WARN__} = sub { };
    },
);

if ($?) {
    # It's maybe ActivePerl's bug.
    # http://ppm4.activestate.com/MSWin32-x86/5.12/1200/T/TO/TOKUHIROM/Test-TCP-1.11.d/log-20101221T221845.txt
    diag "test_tcp() leaks \$?. Maybe it's Perl bug?: $?";
    $? = 0;
}

ok 1, 'test finished.';
