requires 'IO::Socket::INET';
requires 'Test::SharedFork', '0.19';
requires 'perl', '5.00800';

on configure => sub {
    requires 'Module::Build::Tiny';
};

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.59';
    requires 'Test::More', '0.98';
};
