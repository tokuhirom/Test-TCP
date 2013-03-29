requires 'perl', '5.00800';
requires 'IO::Socket::INET';
requires 'Test::SharedFork', '0.19';

on build => sub {
    requires 'Test::More', '0.98';
};
