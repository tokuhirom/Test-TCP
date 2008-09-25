use warnings;
use strict;

package MyEchoServer;
use IO::Socket::INET;

sub new {
    my ($class, $port) = @_;

    my $sock = IO::Socket::INET->new(
        LocalPort => $port,
        LocalAddr => '127.0.0.1',
        Proto     => 'tcp',
        Listen    => 5,
        Type      => SOCK_STREAM,
    ) or die "Cannot open server socket: $!";
    bless { sock => $sock }, $class;
}

sub run {
    my $self = shift;

    while (my $remote = $self->{sock}->accept) {
        while (my $line = <$remote>) {
            print {$remote} $line;
            return close $self->{sock} if $line =~ /quit/;
        }
    }
}

package main;
use strict;
use warnings;
use Test::More tests => 2;
use Test::TCP;
use IO::Socket::INET;

test_tcp(
    client => sub {
        my $port = shift;
        my $sock = IO::Socket::INET->new(
            PeerPort => $port,
            PeerAddr => '127.0.0.1',
            Proto    => 'tcp'
        ) or die "Cannot open client socket: $!";
        print {$sock} "foo\n";
        my $res = <$sock>;
        is $res, "foo\n";
        print {$sock} "bar\n";
        my $res2 = <$sock>;
        is $res2, "bar\n";
        print {$sock} "quit\n";
    },
    server => sub {
        my $port = shift;
        MyEchoServer->new($port)->run;
    },
);

