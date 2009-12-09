use strict;
use warnings;
use App::Prove;
use Test::More tests => 1;

my $app = App::Prove->new;
$app->process_args('-j9', 't/sub1.st', 't/sub2.st');
ok($app->run);

