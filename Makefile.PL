sub author_tests { } # placeholder

use inc::Module::Install;
name 'Test-TCP';
all_from 'lib/Test/TCP.pm';

requires 'IO::Socket::INET' => 0;
requires 'Test::SharedFork' => 0.09;

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
author_tests 'xt';
auto_include;
WriteAll;

