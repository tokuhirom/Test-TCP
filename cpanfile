requires 'perl', 5.008_001;
requires 'IO::Socket::INET';
requires 'IO::Socket::IP';
requires 'Test::SharedFork', '0.29';
requires 'Test::More';
requires 'Time::HiRes';

on test => sub {
    requires 'Test::More', '0.98';
    requires 'File::Temp';
    requires 'Socket';
};


on develop => sub {
    requires 'Perl::Critic', '1.105';
    requires 'Test::Perl::Critic', '1.02';
    requires 'File::Which';
};
