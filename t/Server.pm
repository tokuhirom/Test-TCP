package t::Server;
use strict;
use warnings;
use base qw/Exporter/;
use IO::Socket::INET;

our @EXPORT = qw/new_sock/;

sub new_sock {
    my $port = shift;
    my $sock = IO::Socket::INET->new(
        LocalPort => $port,
        LocalAddr => '127.0.0.1',
        Proto     => 'tcp',
        Listen    => 5,
        Type      => SOCK_STREAM,
        (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
    ) or die "Cannot open server socket: $!";
    return $sock;
}

sub new {
    my ($class, $port) = @_;

    my $sock = new_sock($port);
    bless { sock => $sock }, $class;
}

sub run {
    my ($self, $code) = @_;

    while (my $remote = $self->{sock}->accept) {
        while (my $line = <$remote>) {
            $code->($remote, $line);
        }
    }
}

1;
