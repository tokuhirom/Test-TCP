sub author_tests { } # placeholder

use inc::Module::Install;
name 'Test-TCP';
all_from 'lib/Test/TCP.pm';

requires 'IO::Socket::INET' => 0;
requires 'Test::SharedFork' => 0.14;

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.98;
author_tests 'xt';
WriteAll;

