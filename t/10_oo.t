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

plan tests => 22;

my $server = Test::TCP->new(
    code => sub {
        my $port = shift;
        ok $port, "test case for sharedfork" for 1..10;
        t::Server->new($port)->run(sub {
            note "new request";
            my ($remote, $line, $sock) = @_;
            print {$remote} $line;
        });
    }
);

ok $server->port, "test case for sharedfork" for 1..10;
my $sock = IO::Socket::INET->new(
    PeerPort => $server->port,
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

if ($?) {
    # It's maybe ActivePerl's bug.
    # http://ppm4.activestate.com/MSWin32-x86/5.12/1200/T/TO/TOKUHIROM/Test-TCP-1.11.d/log-20101221T221845.txt
    diag "test_tcp() leaks \$?. Maybe it's Perl bug?: $?";
    $? = 0;
}

done_testing;

