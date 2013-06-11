package t::Server;
use strict;
use warnings;
use base qw/Exporter/;
use IO::Socket;

our @EXPORT = qw/new_sock/;

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

sub new_sock {
    my $port = shift;
    my $sock = $io_socket_module_name->new(
        LocalPort => $port,
        LocalAddr => 'localhost',
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
