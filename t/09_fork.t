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

plan tests => 6;

test_tcp 
    client => sub {
        my $port = shift;

        my $pid = fork();
        if (! ok defined $pid, "Successfully forked child $pid") {
            return diag("Could not fork: $!");
        }

        if (! $pid) {
            eval {
                ok 1, "Successfully executed child $$";
            };
            my $e = $@;
            if (! ok !$e, "child exited normally") {
                diag( "Encountered an error $e" );
            }
            exit;
        }

        waitpid($pid, 0);

        # after the child has exited, we need to make sure that
        # the server hasn't gone away.
        my $sock = IO::Socket::INET->new(
            PeerPort => $port,
            PeerAddr => '127.0.0.1',
            Proto    => 'tcp'
        );
        if (! ok $sock, "socket is connected") {
            return diag("Cannot open client socket: $!");
        }

        print {$sock} "Hello server\n";
        my $res = <$sock>;
        is $res, "Hello server\n", "got expected reply";
    },
    server => sub {
        my $port = shift;
        t::Server->new($port)->run(sub {
            note "new request";
            my ($remote, $line, $sock) = @_;
            print {$remote} $line;
        });
    }
;

if ($?) {
    # It's maybe ActivePerl's bug.
    # http://ppm4.activestate.com/MSWin32-x86/5.12/1200/T/TO/TOKUHIROM/Test-TCP-1.11.d/log-20101221T221845.txt
    diag "test_tcp() leaks \$?. Maybe it's Perl bug?: $?";
    $? = 0;
}
