use strict;
use warnings;
 
use Test::More 0.98;

plan skip_all => "AUTHOR_TESTING is required." unless $ENV{AUTHOR_TESTING};

eval "use Test::DependentModules qw( test_module )";
plan skip_all => "Test::DependentModules required for testing dependent modules" if $@;
 
test_module('Monoceros');
test_module('Plack');

done_testing;
