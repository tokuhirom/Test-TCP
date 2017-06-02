package t::ServerUNIX;
use strict;
use warnings;
use IO::Socket::UNIX;
use base q/t::Server/;

sub new {
    my ($class, $path) = @_;

    my $sock = IO::Socket::UNIX->new(
        Local  => $path,
        Type   => SOCK_STREAM,
        Listen => 1,
    );
    bless { sock => $sock }, $class;
}

1;
