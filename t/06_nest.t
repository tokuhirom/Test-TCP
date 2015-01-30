use strict;
use warnings;
use Config;
use Test::TCP;
use Test::More;
use t::Server;

plan skip_all => "fork not supported on this platform"
  unless $Config::Config{d_fork} || $Config::Config{d_pseudofork} ||
    (($^O eq 'MSWin32' || $^O eq 'NetWare') and
     $Config::Config{useithreads} and
     $Config::Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

plan tests => 1;

test_tcp(
    client => sub {
        my $port1 = shift;
        test_tcp(
            client => sub {
                my $port2 = shift;
                isnt $port1, $port2, "$port1, $port2";
            },
            server => sub {
                my $port2 = shift;
                t::Server->new($port2)->run;
            },
        );
    },
    server => sub {
        my $port1 = shift;
        t::Server->new($port1)->run;
    },
);

if ($?) {
    diag "test_tcp() leaks \$?. Maybe it's Perl bug?: $?";
    $? = 0;
}
