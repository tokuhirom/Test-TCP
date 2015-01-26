package Net::EmptyPort;
use strict;
use warnings;
use base qw/Exporter/;
use IO::Socket::INET;
use Time::HiRes ();

our @EXPORT = qw/ empty_port check_port wait_port /;
our @EXPORT_OK = qw/ empty_port_multi /;

# get a empty port on 49152 .. 65535
# http://www.iana.org/assignments/port-numbers
sub empty_port {
    my ($port) = empty_port_multi(count=>1,start=>$_[0],proto=>$_[1]);
    die "empty port not found" unless $port;
    return $port;
}
sub empty_port_multi {
    my (%opts) = @_;

    my $port = do {
        if (defined $opts{start}) {
            my $p = $opts{start};
            $p = 49152 unless $p =~ /^[0-9]+$/ && $p < 49152;
            $p;
        } else {
            50000 + (int(rand()*1500) + abs($$)) % 1500;
        }
    };
    my $proto = $opts{proto}? lc($opts{proto}) : 'tcp';
    my $count = $opts{count};
    $count=1 if $count<1;

    my @found_ports=();

    while ( $port++ < 65000 ) {
        # Remote checks don't work on UDP, and Local checks would be redundant here...
        next if ($proto eq 'tcp' && check_port($port));

        my $sock = IO::Socket::INET->new(
            (($proto eq 'udp') ? () : (Listen => 5)),
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => $proto,
            (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
        );
        push @found_ports,$port if $sock;

        return @found_ports if @found_ports == $count;
    }

    return @found_ports;
}

sub check_port {
    my $port = $_[0];
    my $proto = $_[1] ? lc($_[1]) : 'tcp';

    # for TCP, we do a remote port check
    # for UDP, we do a local port check, like empty_port does
    my $sock = ($proto eq 'tcp') ?
        IO::Socket::INET->new(
            Proto    => 'tcp',
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
        ) :
        IO::Socket::INET->new(
            Proto     => $proto,
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
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
    my ($port, $max_wait, $proto);
    if (@_==4) {
        # backward compat.
        ($port, (my $sleep), (my $retry), $proto) = @_;
        $max_wait = $sleep * $retry;
        $proto = $proto ? lc($proto) : 'tcp';
    } else {
        ($port, $max_wait, $proto) = @_;
        $proto = $proto ? lc($proto) : 'tcp';
    }

    $max_wait = 10 unless defined $max_wait;
    my $waiter = _make_waiter($max_wait);

    while ( $waiter->() ) {
        if ($^O eq 'MSWin32' ? `$^X -MTest::TCP::CheckPort -echeck_port $port $proto` : check_port( $port, $proto )) {
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

=item C<< empty_port() >>

    my $port = empty_port();

Get the available port number, you can use.

Normally, empty_port() finds empty port number from 49152..65535.
See L<http://www.iana.org/assignments/port-numbers>

But you want to use another range, use a following form:

    # 5963..65535
    my $port = empty_port(5963);

You can also find an empty UDP port by specifying the protocol as
the second parameter:

    my $port = empty_port(1024, 'udp');
    # use 49152..65535 range
    my $port = empty_port(undef, 'udp');

If C<empty_port> can not find a port to return, it will C<die>.

=item C<< empty_port_multi(...) >>

    my @ports = empty_port_multi(count=>5);

Sometimes you need a set of open ports. Calling C<empty_port> multiple
times without creating a listening socket after each call does not
guarantee you'll get different ports each time. C<empty_port_multi>
guarantees that.

In addition to passing the number of ports you want, you can pass the
port number to start from, and the protocol:

    my @ports = empty_port_multi(count=>5,start=>5963,proto=>'udp');

All parameters are optional, with the same defaults as C<empty_port>;
C<count> defaults to 1.

If C<empty_port_multi> can not find enough empty ports, it will return
the ones it found (possibly none).

C<empty_port_multi> is not exported by default, you have to ask for
it:

   use Net::EmptyPort 'empty_port_multi';
   # or
   use Net::EmptyPort qw(:DEFAULT empty_port_multi);
   # or
   use Net::EmptyPort qw(:ALL);

(see L<Exporter> for details).

=item C<< check_port($port:Int) >>

    my $true_or_false = check_port(5000);

Checks if the given port is already in use. Returns true if it is in use (i.e. if the port is NOT free). Returns false if the port is free.

Also works for UDP:

    my $true_or_false = check_port(5000, 'udp');

=item C<< wait_port($port:Int[, $max_wait:Number,$proto:String]) >>

Waits for a particular port is available for connect.

This method waits the C<< $port >> number is ready to accept a request.

C<$port> is a port number to check.

Sleep up to C<$max_wait> seconds (10 seconds by default) for checking the
port. Pass negative C<$max_wait> value to wait infinitely.

I<Return value> : Return true if the port is available, false otherwise.

B<Incompatible changes>: Before 2.0, C<< wait_port($port:Int[, $sleep:Number, $retry:Int, $proto:String]) >> is a signature.

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
