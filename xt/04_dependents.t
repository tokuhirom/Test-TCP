use strict;
use warnings;
 
use Test::More 0.98;

BEGIN {
    plan skip_all => "AUTHOR_TESTING is required." unless $ENV{AUTHOR_TESTING};
}

use File::Which;
use File::Temp qw(tempdir);

plan skip_all => "No cpanm" unless which('cpanm');

my $tmp = tempdir(CLEANUP => 1);
is(system("cpanm --notest -l $tmp ."), 0);
for (qw(Monoceros Plack)) {
    is(system("cpanm -l $tmp --reinstall $_"), 0, $_);
}

done_testing;
