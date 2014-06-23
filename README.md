# NAME

Test::TCP - testing TCP program

# SYNOPSIS

    use Test::TCP;

    my $server = Test::TCP->new(
        code => sub {
            my $port = shift;
            ...
        },
    );
    my $client = MyClient->new(host => '127.0.0.1', port => $server->port);
    undef $server; # kill child process on DESTROY

Using memcached:

    use Test::TCP;

    my $memcached = Test::TCP->new(
        code => sub {
            my $port = shift;

            exec $bin, '-p' => $port;
            die "cannot execute $bin: $!";
        },
    );
    my $memd = Cache::Memcached->new({servers => ['127.0.0.1:' . $memcached->port]});
    ...

And functional interface is available:

    use Test::TCP;
    test_tcp(
        client => sub {
            my ($port, $server_pid) = @_;
            # send request to the server
        },
        server => sub {
            my $port = shift;
            # run server
        },
    );

# DESCRIPTION

Test::TCP is test utilities for TCP/IP programs.

# METHODS

- test\_tcp

    Functional interface.

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
            port => 8080,
            max_wait => 3, # seconds
        );

- wait\_port

        wait_port(8080);

    Waits for a particular port is available for connect.

# OO-ish interface

- my $server = Test::TCP->new(%args);

    Create new instance of Test::TCP.

    Arguments are following:

    - $args{auto\_start}: Boolean

        Call `$server->start()` after create instance.

        Default: true

    - $args{code}: CodeRef

        The callback function. Argument for callback function is: `$code->($pid)`.

        This parameter is required.

    - $args{max\_wait} : Number

        Will wait for at most `$max_wait` seconds before checking port.

        See also [Net::EmptyPort](https://metacpan.org/pod/Net::EmptyPort).

        _Default: 10_

- $server->start()

    Start the server process. Normally, you don't need to call this method.

- $server->stop()

    Stop the server process.

- my $pid = $server->pid();

    Get the pid of child process.

- my $port = $server->port();

    Get the port number of child process.

# FAQ

- How to invoke two servers?

    You can call test\_tcp() twice!

        test_tcp(
            client => sub {
                my $port1 = shift;
                test_tcp(
                    client => sub {
                        my $port2 = shift;
                        # some client code here
                    },
                    server => sub {
                        my $port2 = shift;
                        # some server2 code here
                    },
                );
            },
            server => sub {
                my $port1 = shift;
                # some server1 code here
            },
        );

    Or use OO-ish interface instead.

        my $server1 = Test::TCP->new(code => sub {
            my $port1 = shift;
            ...
        });
        my $server2 = Test::TCP->new(code => sub {
            my $port2 = shift;
            ...
        });

        # your client code here.
        ...

- How do you test server program written in other languages like memcached?

    You can use `exec()` in child process.

        use strict;
        use warnings;
        use utf8;
        use Test::More;
        use Test::TCP 1.08;
        use File::Which;

        my $bin = scalar which 'memcached';
        plan skip_all => 'memcached binary is not found' unless defined $bin;

        my $memcached = Test::TCP->new(
            code => sub {
                my $port = shift;

                exec $bin, '-p' => $port;
                die "cannot execute $bin: $!";
            },
        );

        use Cache::Memcached;
        my $memd = Cache::Memcached->new({servers => ['127.0.0.1:' . $memcached->port]});
        $memd->set(foo => 'bar');
        is $memd->get('foo'), 'bar';

        done_testing;

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

# THANKS TO

kazuhooku

dragon3

charsbar

Tatsuhiko Miyagawa

lestrrat

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
