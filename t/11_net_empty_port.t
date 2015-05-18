use strict;
use warnings;
use IO::Socket::IP;
use Test::More;
use Net::EmptyPort;

sub doit {
    my $host = shift;

    my $port = empty_port();
    ok "found an empty port";

    ok !wait_port({ host => $host, port => $port, max_wait => 0.1 }), "port is closed";

    my $sock = IO::Socket::IP->new(
        LocalAddr => $host,
        LocalPort => $port,
        Listen    => 1,
        V6Only    => 1,
    ) or die "Couldn't create socket: $!";

    ok wait_port({ host => $host, port => $port, max_wait => 3 }), "port is open";
};

ok can_bind('127.0.0.1'), 'bind to 127.0.0.1';
ok ! can_bind('8.8.8.8'), 'bind to an anvailable address';

subtest 'v4' => sub {
    doit('127.0.0.1');
};

subtest 'v6' => sub {
    plan skip_all => "IPv6 not supported"
        unless can_bind('::1');
    ok "found an empty port";
    doit('::1');
};

my $port = empty_port (8080, 'tcp');
ok ($port, 'Non hashref arg to empty_port');
cmp_ok ($port, '<', 49152, 'Specified low port to empty_port');
$port = empty_port (50000, 'tcp');
cmp_ok ($port, '>', 49151, 'Specified high port to empty_port');
$port = empty_port ('alpha', 'tcp');
cmp_ok ($port, '>', 49151, 'Specified non-numeric port to empty_port');
$port = empty_port ('alpha', 'udp');
cmp_ok ($port, '>', 49151, 'Specified non-numeric port and udp proto to empty_port');


$port = empty_port ();
ok (!wait_port ($port, 0.1, 2, 'tcp'),
	'4 args to wait_port (backwards compat)');
ok (!wait_port ($port, 0.2, 'tcp'),
	'3 args to wait_port');
eval { wait_port (); };
like ($@, qr/Expected .PeerService./, 'No args to wait_port is fatal');
ok (!wait_port ($port), 'No max_wait to wait_port');

eval { check_port (); };
like ($@, qr/Expected .PeerService./, 'No args to check_port is fatal');
ok (!check_port (empty_port(), 'tcp'), '2 args to check_port');

done_testing;
