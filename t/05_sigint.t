use strict;
use warnings;
use Test::TCP;
use IO::Socket::INET;
use POSIX;
use Test::More;
use Config;

plan skip_all => "this test requires SIGUSR1" unless $Config{sig_name} =~ /USR1/;
plan skip_all => "Perl<5.8.8 does not supports \${^CHILD_ERROR_NATIVE}" if $] <= 5.008008;
plan tests => 2;

my $pid = Test::SharedFork->fork;
# my $killed_server = 0;
# $SIG{USR1} = sub { $killed_server = 1 };
if ($pid > 0) {
    sleep 1;
    kill 'INT', $pid;
    waitpid($pid, 0);
    # NOTE. $? is broken on AIX platform. see also __END__ comments on this file.
    diag "\$Config{sig_name}: " . $Config{sig_name};
    diag "CHILD_ERROR_NATIVE: " . ${^CHILD_ERROR_NATIVE};
    diag "\$?: " . $?;

    ok POSIX::WIFSIGNALED(${^CHILD_ERROR_NATIVE});
    is [split / /, $Config{sig_name}]->[POSIX::WTERMSIG(${^CHILD_ERROR_NATIVE})], 'INT', "sigint";
#   ok $killed_server, "really killed";
} elsif ($pid == 0) {
#   $SIG{CHLD} = sub {
#       kill 'USR1', POSIX::getppid();
#   };
    test_tcp(
        client => sub {
            sleep 3;
        },
        server => sub {
            my $port = shift;
            my $sock = IO::Socket::INET->new(
                LocalAddr => '127.0.0.1',
                LocalPort => $port,
                Listen    => 5,
                ReuseAddr => 1,
            ) or die $!;
            sleep 6;
        },
    );
    fail "should not reach here";
} else {
    die 'sucks';
}

__END__

Following comments are copy & paste from : https://rt.cpan.org/Public/Bug/Display.html?id=72779

The test suite passes for RHEL5 and Solaris 10, but fails on AIX 6.  The results are
independent of the core perl version.   The test failure output is:

[efsops@shou18l560-02 Test-TCP-1.13]$ perl -Mblib t/05_sigint.t
1..2
ok 1
not ok 2 - sigint
#   Failed test 'sigint'
#   at t/05_sigint.t line 20.
#          got: 'ZERO'
#     expected: 'INT'
# Looks like you failed 1 test of 2.

The reason for the failure is somewhat subtle.   On AIX, the value assigned to $? by wiatpid
can not be passed to the POSIX functions.  However, if the ${^CHILD_ERROR_NATIVE} value is
used, then this works fine, and on ALL of the above platforms.

While the root cause of this problem is likely a bug in perl related to how $? is handled
internally, the patch I've provided seems correct when you consider that the documentation
for CHILD_ERROR_NATIVE specifically documents THIS variable (and not $?/$CHILD_ERROR) as
the one to pass to the POSIX functions.

I suspect that passing $? works for backwards compatibility, but clearly, it doesn't work on
ALL platforms, and the core perl tests seem to reflect this as well.

