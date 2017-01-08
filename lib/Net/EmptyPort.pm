package Net::EmptyPort;
use strict;
use warnings;
use base qw/Exporter/;
use IO::Socket::IP;
use Time::HiRes ();

our @EXPORT = qw/ can_bind empty_port check_port wait_port /;
our @EXPORT_OK = qw/ listen_socket /;

sub can_bind {
    my ($host, $port, $proto) = @_;
    # The following must be split across two statements, due to
    # https://rt.perl.org/Public/Bug/Display.html?id=124248
    my $s = _listen_socket($host, $port, $proto);
    return defined $s;
}

sub _listen_socket {
    my ($host, $port, $proto) = @_;
    $port  ||= 0;
    $proto ||= 'tcp';
    IO::Socket::IP->new(
        (($proto eq 'udp') ? () : (Listen => 5)),
        LocalAddr => $host,
        LocalPort => $port,
        Proto     => $proto,
        V6Only    => 1,
        (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
    );
}

sub listen_socket {
    my ($host, $proto) = @{$_[0]}{qw(host proto)};
    $host = '127.0.0.1' unless defined $host;
    return _listen_socket($host, undef, $proto);
}

# get a empty port on 49152 .. 65535
# http://www.iana.org/assignments/port-numbers
sub empty_port {
    my ($host, $port, $proto) = @_ && ref $_[0] eq 'HASH' ? ($_[0]->{host}, $_[0]->{port}, $_[0]->{proto}) : (undef, @_);
    $host = '127.0.0.1'
        unless defined $host;
    if (defined $port) {
        $port = 49152 unless $port =~ /^[0-9]+$/ && $port < 49152;
    } else {
        $port = 50000 + (int(rand()*1500) + abs($$)) % 1500;
    }
    $proto = $proto ? lc($proto) : 'tcp';

    while ( $port++ < 65000 ) {
        # Remote checks don't work on UDP, and Local checks would be redundant here...
        next if ($proto eq 'tcp' && check_port({ host => $host, port => $port }));
        return $port if can_bind($host, $port, $proto);
    }
    die "empty port not found";
}

sub check_port {
    my ($host, $port, $proto) = @_ && ref $_[0] eq 'HASH' ? ($_[0]->{host}, $_[0]->{port}, $_[0]->{proto}) : (undef, @_);
    $host = '127.0.0.1'
        unless defined $host;
    $proto = $proto ? lc($proto) : 'tcp';

    # for TCP, we do a remote port check
    # for UDP, we do a local port check, like empty_port does
    my $sock = ($proto eq 'tcp') ?
        IO::Socket::IP->new(
            Proto    => 'tcp',
            PeerAddr => $host,
            PeerPort => $port,
            V6Only   => 1,
        ) :
        IO::Socket::IP->new(
            Proto     => $proto,
            LocalAddr => $host,
            LocalPort => $port,
            V6Only   => 1,
            (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
        )
    ;

    if ($sock) {
        close $sock;
        return 1; # The port is used.
    }
    else {
        return 0; # The port is not used.
    }

}

sub _make_waiter {
    my $max_wait = shift;
    my $waited = 0;
    my $sleep  = 0.001;

    return sub {
        return 0 if $max_wait >= 0 && $waited > $max_wait;

        Time::HiRes::sleep($sleep);
        $waited += $sleep;
        $sleep  *= 2;

        return 1;
    };
}

sub wait_port {
    my ($host, $port, $max_wait, $proto);
    if (@_ && ref $_[0] eq 'HASH') {
        ($host, $port, $max_wait, $proto) = ($_[0]->{host}, $_[0]->{port}, $_[0]->{max_wait}, $_[0]->{proto});
    } elsif (@_==4) {
        # backward compat.
        ($port, (my $sleep), (my $retry), $proto) = @_;
        $max_wait = $sleep * $retry;
    } else {
        ($port, $max_wait, $proto) = @_;
    }
    $host = '127.0.0.1' unless defined $host;
    $max_wait ||= 10;
    $proto = $proto ? lc($proto) : 'tcp';
    my $waiter = _make_waiter($max_wait);

    while ( $waiter->() ) {
        if ($^O eq 'MSWin32' ? `$^X -MTest::TCP::CheckPort -echeck_port $host $port $proto` : check_port({ host => $host, port => $port, proto => $proto })) {
            return 1;
        }
    }
    return 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Net::EmptyPort - find a free TCP/UDP port

=head1 SYNOPSIS

    use Net::EmptyPort qw(empty_port check_port);

    # get a socket listening on a random free port
    my $socket = listen_socket();

    # get a random free port
    my $port = empty_port();

    # check if a port is already used
    if (check_port(5000)) {
        say "Port 5000 already in use";
    }

=head1 DESCRIPTION

Net::EmptyPort helps finding an empty TCP/UDP port.

=head1 METHODS

=over 4

=item C<< listen_socket() >>

=item C<< listen_socket(\%args) >>


    my $socket = listen_socket();

Returns a socket listening on a free port.

The function recognizes the following keys in the hashref argument.

=over 4

=item C<< host >>

The address on which to listen.  Default is C<< 127.0.0.1 >>.

=item C<< proto >>

Name of the protocol.  Default is C<< tcp >>.
You can get an UDP socket by specifying C<< udp >>.

=back

=item C<< empty_port() >>

=item C<< empty_port(\%args) >>

=item C<< empty_port($port) >>

=item C<< empty_port($port, $proto) >>

    my $port = empty_port();

Returns a port number that is NOT in use.

The function recognizes the following keys when given a hashref as the argument.

=over 4

=item C<< host >>

specifies the address on which the search should be performed.  Default is C<< 127.0.0.1 >>.

=item C<< port >>

Lower bound of the search for an empty port.  If omitted, the function searches for an empty port within 49152..65535.

See L<http://www.iana.org/assignments/port-numbers>

=item C<< proto >>

Name of the protocol.  Default is C<< tcp >>. You can find an empty UDP port by specifying C<< udp >>.

=back

To maintain backwards compatibility, the function accepts scalar arguments as well.  For example, you can also find an empty UDP port by specifying the protocol as
the second parameter:

    my $port = empty_port(1024, 'udp');
    # use 49152..65535 range
    my $port = empty_port(undef, 'udp');

=item C<< check_port(\%args) >>

=item C<< check_port($port) >>

=item C<< check_port($port, $proto) >>

    my $true_or_false = check_port(5000);

Checks if the given port is already in use. Returns true if it is in use (i.e. if the port is NOT free). Returns false if the port is free.

The function recognizes the following keys when given a hashref as the argument.

=over 4

=item C<< host >>

specifies the address on which the search should be performed.  Default is C<< 127.0.0.1 >>.

=item C<< port >>

specifies the port to check.  This argument is mandatory.

=item C<< proto >>

name of the protocol.  Default is C<< tcp >>.

=back

To maintain backwards compatibility, the function accepts scalar arguments as well in the form described above.

=item C<< wait_port(\%args) >>

=item C<< wait_port($port) >>

=item C<< wait_port($port, $max_wait) >>

=item C<< wait_port($port, $max_wait, $proto) >>

Waits until a particular port becomes ready to connect to.  Returns true if the port becomes ready, or false if otherwise.

The function recognizes the following keys when given a hashref as the argument.

=over 4

=item C<< host >>

specifies the address on which the search should be performed.  Default is C<< 127.0.0.1 >>.

=item C<< port >>

specifies the port to check.  This argument is mandatory.

=item C<< max_wait >>

maximum seconds to wait for (default is 10 seconds).  Pass a negative value to wait infinitely.

=item C<< proto >>

name of the protocol.  Default is C<< tcp >>.

=back

To maintain backwards compatibility, the function accepts scalar arguments as well in the form described above.

B<Incompatible changes>: Before 2.0, C<< wait_port($port:Int[, $sleep:Number, $retry:Int, $proto:String]) >> is a signature.

=item C<< can_bind($host) >>

=item C<< can_bind($host, $port) >>

=item C<< can_bind($host, $port, $proto) >>

Checks if the application is capable of binding to given port.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 THANKS TO

kazuhooku

dragon3

charsbar

Tatsuhiko Miyagawa

lestrrat

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
