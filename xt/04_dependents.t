use strict;
use warnings;
 
use Test::More;
eval "use Test::DependentModules qw( test_all_dependents )";
plan skip_all => "Test::DependentModules required for testing dependent modules" if $@;
 
test_all_dependents('Test::TCP');
