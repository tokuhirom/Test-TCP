package Test::TCP;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.02';
use Sub::Exporter -setup => {
    exports => [
        qw/ empty_port test_tcp wait_port /
    ],
    groups => { default => [':all'] }
};
use IO::Socket::INET;
use Params::Validate ':all';

sub empty_port {
    my $port = shift || 10000;
    $port = 19000 unless $port =~ /^[0-9]+$/ && $port < 19000;

    while ( $port++ < 20000 ) {
        my $sock = IO::Socket::INET->new(
            Listen    => 5,
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp'
        );
        return $port if $sock;
    }
    die "empty port not found";
}

sub test_tcp {
    my %args = validate(@_, {
        client => CODEREF,
        server => CODEREF,
        port   => {
            type => SCALAR,
            default => empty_port(),
        },
    });

    my $port = $args{port};

    if ( my $pid = fork() ) {
        # parent.
        wait_port($port);

        $args{client}->($port);

        kill TERM => $pid;
        waitpid( $pid, 0 );
    }
    elsif ( $pid == 0 ) {
        # child
        $args{server}->($port);
    }
    else {
        die "fork failed: $!";
    }
}

sub _check_port {
    my ($port) = @_;

    my $remote = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
    );
    if ($remote) {
        close $remote;
        return 1;
    }
    else {
        return 0;
    }
}

sub wait_port {
    my $port = shift;

    my $retry = 10;
    while ( $retry-- ) {
        return if _check_port($port);
        sleep 1;
    }
    die "cannot open port: $port";
}

1;
__END__

=encoding utf8

=head1 NAME

Test::TCP - testing TCP program

=head1 SYNOPSIS

    use Test::TCP;
    my $port = empty_port();
    test_tcp(
        client => sub {
            my $port = shift;
            # send request to the server
        },
        server => sub {
            my $port = shift;
            # run server
        },
    );

=head1 DESCRIPTION

Test::TCP is test utilities for TCP/IP program.

=head1 METHODS

=over 4

=item empty_port

    my $port = empty_port();

search empty port

=item test_tcp

    test_tcp(
        client => sub {
            my $port = shift;
            # send request to the server
        },
        server => sub {
            my $port = shift;
            # run server
        },
        # optional
        port => 8080
    );

=item wait_port

    wait_port(8080);

Waits for a particular port is available

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
