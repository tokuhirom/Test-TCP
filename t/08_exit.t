use strict;
use warnings;
use Config;
use Test::More;
use Test::TCP;
use File::Temp ();
use Fcntl qw/:seek/;
use t::Server;
use POSIX;

plan skip_all => "fork not supported on this platform"
  unless $Config::Config{d_fork} || $Config::Config{d_pseudofork} ||
    (($^O eq 'MSWin32' || $^O eq 'NetWare') and
     $Config::Config{useithreads} and
     $Config::Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

plan tests => 5;

my $tmp = File::Temp->new();

my $pid = fork();
die "cannot fork: $!" unless defined $pid;
if ($pid) { # parent
    # waiting 'client'
    SKIP: {
        waitpid($pid, 0);
        skip 'not implemented on Win32', 4 if $^O eq 'MSWin32';
        ok WIFEXITED($?);
        ok !WIFSIGNALED($?);
        ok !WIFSTOPPED($?);
        is WEXITSTATUS($?), 1;
    }

    # killing 'server'
    {
        seek $tmp, 0, SEEK_SET;
        my $child_pid = do { local $/; <$tmp> };
        is kill(($^O eq 'MSWin32' ? 'KILL' : 'TERM'), $child_pid), 0;
        my $kid;
        do {
            $kid = waitpid($child_pid, 0);
        } while $kid > 0;
    }
} else { # child
    test_tcp(
        client => sub {
            my $port = shift;
            note "CLIENT: $$";
            exit 1;
        },
        server => sub {
            my $port = shift;
            note "SEVER: $$";
            print {$tmp} $$;
            $tmp->close;
            t::Server->new($port)->run(sub {
                note "new request";
                my ($remote, $line, $sock) = @_;
                print {$remote} $line;
            });
        },
    );
}

