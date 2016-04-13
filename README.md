# NAME

Test::TCP - testing TCP program

# SYNOPSIS

    use Test::TCP;

    my $server = Test::TCP->new(
        listen => 1,
        code => sub {
            my $socket = shift;
            ...
        },
    );
    my $client = MyClient->new(host => '127.0.0.1', port => $server->port);
    undef $server; # kill child process on DESTROY

If using a server that can only accept a port number, e.g. memcached:

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

**N.B.**: This is vulnerable to race conditions, if another process binds
to the same port after [Net::EmptyPort](https://metacpan.org/pod/Net::EmptyPort) found it available.

And functional interface is available:

    use Test::TCP;
    test_tcp(
        listen => 1,
        client => sub {
            my ($port, $server_pid) = @_;
            # send request to the server
        },
        server => sub {
            my $socket = shift;
            # run server, calling $socket->accept
        },
    );

    test_tcp(
        client => sub {
            my ($port, $server_pid) = @_;
            # send request to the server
        },
        server => sub {
            my $port = shift;
            # run server, binding to $port
        },
    );

# DESCRIPTION

Test::TCP is a test utility to test TCP/IP-based server programs.

# METHODS

- test\_tcp

    Functional interface.

        test_tcp(
            listen => 1,
            client => sub {
                my $port = shift;
                # send request to the server
            },
            server => sub {
                my $socket = shift;
                # run server
            },
            # optional
            host => '127.0.0.1', # specify '::1' to test using IPv6
            port => 8080,
            max_wait => 3, # seconds
        );

    If `listen` is false, `server` is instead passed a port number that
    was free before it was called.

- wait\_port

        wait_port(8080);

    Waits for a particular port is available for connect.

# Object Oriented interface

- my $server = Test::TCP->new(%args);

    Create new instance of Test::TCP.

    Arguments are following:

    - $args{auto\_start}: Boolean

        Call `$server->start()` after create instance.

        Default: true

    - $args{code}: CodeRef

        The callback function. Argument for callback function is:
        `$code->($socket)` or `$code->($port)`,
        depending on the value of `listen`.

        This parameter is required.

    - $args{max\_wait} : Number

        Will wait for at most `$max_wait` seconds before checking port.

        See also [Net::EmptyPort](https://metacpan.org/pod/Net::EmptyPort).

        _Default: 10_

    - $args{listen} : Boolean

        If true, open a listening socket and pass this to the callback.
        Otherwise find a free port and pass the number of it to the callback.

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

    Or use the OO interface instead.

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

- How do I use address other than "127.0.0.1" for testing?

    You can use the `host` parameter to specify the bind address.

        # let the server bind to "0.0.0.0" for testing
        test_tcp(
            client => sub {
                ...
            },
            server => sub {
                ...
            },
            host => '0.0.0.0',
        );

- How should I write IPv6 tests?

    You should use the \`Net::EmptyPort::can\_bind\` function to check if the program can bind to the loopback address of IPv6, as well as the \`host\` parameter of the \`test\_tcp\` function to specify the same address as the bind address.

        use Net::EmptyPort qw(can_bind);

        plan skip_all => "IPv6 not available"
            unless can_bind('::1');

        test_tcp(
            client => sub {
                ...
            },
            server => sub {
                ...
            },
            host => '::1',
        );

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
