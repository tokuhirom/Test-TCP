use strict;
use warnings;
use Test::TCP;
use IO::Socket::INET;
use POSIX;
use Test::More;
use Config;

plan skip_all => "this test requires SIGUSR1" unless $Config{sig_name} =~ /USR1/;
plan tests => 2;

my $pid = Test::SharedFork->fork;
# my $killed_server = 0;
# $SIG{USR1} = sub { $killed_server = 1 };
if ($pid > 0) {
    sleep 1;
    kill 'INT', $pid;
    waitpid($pid, 0);
    ok POSIX::WIFSIGNALED($?);
    is [split / /, $Config{sig_name}]->[POSIX::WTERMSIG($?)], 'INT', "sigint";
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

