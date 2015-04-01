package t::Server;
use strict;
use warnings;
use base qw/Exporter/;
use IO::Socket::IP;

our @EXPORT = qw/new_sock/;

sub new_sock {
    my ($host, $port) = @_;
    my $sock = IO::Socket::IP->new(
        LocalPort => $port,
        LocalAddr => $host,
        Proto     => 'tcp',
        Listen    => 5,
        Type      => SOCK_STREAM,
        V6Only    => 1,
        (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
    ) or die "Cannot open server socket: $!";
    return $sock;
}

sub new {
    my ($class, $host, $port) = @_;

    my $sock = new_sock($host, $port);
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
