use warnings;
use strict;
use Test::More tests => 22;
use Test::TCP;
use t::Server;

our $io_socket_module_name;
BEGIN {
  if (eval { require IO::Socket::IP }) {
    $io_socket_module_name = 'IO::Socket::IP';
  } elsif (eval { require IO::Socket::INET6 }) {
    $io_socket_module_name = 'IO::Socket::INET6';
  } elsif (eval { require IO::Socket::INET }) {
    $io_socket_module_name = 'IO::Socket::INET';
  }
}

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
my $sock = $io_socket_module_name->new(
    PeerPort => $server->port,
    PeerAddr => 'localhost',
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

