sub author_tests { } # placeholder

use inc::Module::Install;
name 'Test-TCP';
all_from 'lib/Test/TCP.pm';

requires 'IO::Socket::INET' => 1.31;
requires 'Test::SharedFork' => 0.09;

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
test_requires 'YAML';
author_tests 'xt';
use_test_base;
auto_include;
WriteAll;

