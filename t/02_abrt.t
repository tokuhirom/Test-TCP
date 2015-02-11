use strict;
use warnings;
use Test::TCP;
use Test::More;
use Socket;
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

plan skip_all => "win32 doesn't support embedded function named dump()" if $^O eq 'MSWin32';
plan tests => 2;

test_tcp(
    client => sub {
        my $port = shift;
        my $sock = $io_socket_module_name->new(
            PeerPort => $port,
            PeerAddr => 'localhost',
            Proto    => 'tcp'
        ) or die "Cannot open client socket: $!";
        print {$sock} "dump\n";
        my $res = <$sock>;
        is $res, "dump\n";
        $sock->close();
        ok 1;
    },
    server => sub {
        my $port = shift;
        t::Server->new($port)->run(sub {
            my ($remote, $line) = @_;
            print {$remote} $line;
            if ($line =~ /dump/) {
                return CORE::dump()
            }
        });
    },
);
