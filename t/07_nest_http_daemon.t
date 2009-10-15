use strict;
use warnings;
use Test::TCP;
use Test::More;
use t::Server;
use Test::Requires 'HTTP::Daemon', 'HTTP::Proxy';

test_tcp(
    client => sub {
        my $httpd_port = shift;
        test_tcp(
            client => sub {
                my $proxy_port = shift;

                isnt $httpd_port, $proxy_port, "$httpd_port != $proxy_port";

                SKIP: {
                    skip "port error", 2 if $httpd_port == $proxy_port;
                    my $ua = LWP::UserAgent->new();
                    $ua->proxy('http', "http://127.0.0.1:$proxy_port");
                    my $res = $ua->get("http://127.0.0.1:$httpd_port");
                    ok $res->is_success;
                    is $res->content, 'ok';
                };
                done_testing;
            },
            server => sub {
                my $proxy_port = shift;
                ok 1, "started PROXY($proxy_port)!";
                HTTP::Proxy->new( port => $proxy_port )->start();
            },
        );
    },
    server => sub {
        my $httpd_port = shift;
        my $d = HTTP::Daemon->new(
            ReuseAddr => 1,
            LocalPort => $httpd_port,
            LocalAddr => '0.0.0.0'
        ) || die;
        ok 1, "started httpd($httpd_port)!";
        while ( my $c = $d->accept ) {
            while ( my $r = $c->get_request ) {
                ok '100', '200 ok';
                $c->send_response(
                    HTTP::Response->new( 200, 'ok', [], "OK!!!" ) );
            }
            $c->close;
            undef($c);
        }
    },
);

