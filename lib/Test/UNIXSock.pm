package Test::UNIXSock;
use strict;
use warnings;
use 5.00800;
our $VERSION = '2.14';
use base qw/Exporter/;
use IO::Socket::UNIX;
use Test::SharedFork 0.12;
use Test::More ();
use Config;
use POSIX;
use Time::HiRes ();
use Carp ();
use File::Temp qw/ tempdir /;
use Net::EmptyPort ();

our @EXPORT = qw/ test_unix_sock wait_unix_sock /;

my $TERMSIG = 'TERM';

sub test_unix_sock {
    my %args = @_;
    for my $k (qw/client server/) {
        die "missing madatory parameter $k" unless exists $args{$k};
    }
    my $server_code = delete $args{server};
    my $client_code = delete $args{client};

    my $server = Test::UNIXSock->new(
        code => $server_code,
        %args,
    );
    $client_code->($server->path, $server->pid);
    undef $server; # make sure
}

sub wait_unix_sock {
    my ($path, $max_wait);
    if (@_ && ref $_[0] eq 'HASH') {
        $path = $_[0]->{path};
        $max_wait = $_[0]->{max_wait};
    } elsif (@_ == 3) {
        # backward compat
        ($path, (my $sleep), (my $retry)) = @_;
        $max_wait = $sleep * $retry;
    } else {
        ($path, $max_wait) = @_;
    }
    $max_wait ||= 10;
    my $waiter = Net::EmptyPort::_make_waiter($max_wait);
    while ( $waiter->() ) {
        IO::Socket::UNIX->new(
            Type => SOCK_STREAM,
            Peer => $path,
        ) && return 1;
    }
    return 0;
}

# ------------------------------------------------------------------------- 
# OO-ish interface

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    Carp::croak("missing mandatory parameter 'code'") unless exists $args{code};
    my $self = bless {
        auto_start => 1,
        max_wait   => 10,
        _my_pid    => $$,
        %args,
    }, $class;
    unless (defined $self->{path}) {
        $self->{tmpdir} = tempdir( CLEANUP => 1 );
        $self->{path} = $self->{tmpdir} . "/test.sock";
    }
    $self->start()
      if $self->{auto_start};
    return $self;
}

sub pid  { $_[0]->{pid} }
sub path { $_[0]->{path} }

sub start {
    my $self = shift;
    my $pid = fork();
    die "fork() failed: $!" unless defined $pid;

    if ( $pid ) { # parent process.
        $self->{pid} = $pid;
        Test::UNIXSock::wait_unix_sock({ path => $self->path, max_wait => $self->{max_wait} });
        return;
    } else { # child process
        $self->{code}->($self->path);
        # should not reach here
        if (kill 0, $self->{_my_pid}) { # warn only parent process still exists
            warn("[Test::UNIXSocket] Child process does not block(PID: $$, PPID: $self->{_my_pid})");
        }
        exit 0;
    }
}

sub stop {
    my $self = shift;

    return unless defined $self->{pid};
    return unless $self->{_my_pid} == $$;

    kill $TERMSIG => $self->{pid};

    local $?; # waitpid modifies original $?.
    LOOP: while (1) {
        my $kid = waitpid( $self->{pid}, 0 );
        if (POSIX::WIFSIGNALED($?)) {
            my $signame = (split(' ', $Config{sig_name}))[POSIX::WTERMSIG($?)];
            if ($signame =~ /^(ABRT|PIPE)$/) {
                Test::More::diag("your server received SIG$signame");
            }
        }
        if ($kid == 0 || $kid == -1) {
            last LOOP;
        }
    }
    undef $self->{pid};
}

sub DESTROY {
    my $self = shift;
    local $@;
    $self->stop();
}

1;
__END__

=for stopwords OO

=encoding utf8

=head1 NAME

Test::UNIXSock - testing UNIX domain socket program

=head1 SYNOPSIS

    use Test::UNIXSock;

    my $server = Test::UNIXSock->new(
        code => sub {
            my $path = shift;
            ...
        },
    );
    my $client = MyClient->new( sock => $server->path );
    undef $server; # kill child process on DESTROY

Using memcached:

    use Test::UNIXSock;

    my $memcached = Test::UNIXSock->new(
        code => sub {
            my $path = shift;

            exec $bin, '-s' => $path;
            die "cannot execute $bin: $!";
        },
    );
    my $memd = Cache::Memcached->new({servers => [$memcached->path]});
    ...

And functional interface is available:

    use Test::UNIXSock;
    test_unix_sock(
        client => sub {
            my ($path, $server_pid) = @_;
            # send request to the server
        },
        server => sub {
            my $path = shift;
            # run server
        },
    );

=head1 DESCRIPTION

Test::UNIXSock is a test utility to test UNIX domain socket server programs.

=head1 METHODS

=over 4

=item test_unixsock

Functional interface.

    test_unixsock(
        client => sub {
            my $path = shift;
            # send request to the server
        },
        server => sub {
            my $path = shift;
            # run server
        },
        # optional
        path => "/tmp/mytest.sock", # if not specified, create a sock in tmpdir
        max_wait => 3, # seconds
    );


=item wait_unix_sock

    wait_unix_sock({ path => $path });

Waits for a particular path is available for connect.

=back

=head1 Object Oriented interface interface

=over 4

=item my $server = Test::UNIXSock->new(%args);

Create new instance of Test::UNIXSock.

Arguments are following:

=over 4

=item $args{auto_start}: Boolean

Call C<< $server->start() >> after create instance.

Default: true

=item $args{code}: CodeRef

The callback function. Argument for callback function is: C<< $code->($pid) >>.

This parameter is required.

=item $args{max_wait} : Number

Will wait for at most C<$max_wait> seconds before checking port.

See also L<Net::EmptyPort>.

I<Default: 10>

=back

=item $server->start()

Start the server process. Normally, you don't need to call this method.

=item $server->stop()

Stop the server process.

=item my $pid = $server->pid();

Get the pid of child process.

=item my $port = $server->port();

Get the port number of child process.

=back

=head1 FAQ

See L<Test::TCP> FAQ section.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

Fujiwara Shunichiro E<lt>fujiwara.shunichiro@gmail.comE<gt>

=head1 THANKS TO

kazuhooku

dragon3

charsbar

Tatsuhiko Miyagawa

lestrrat

=head1 SEE ALSO

L<Test::TCP>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
