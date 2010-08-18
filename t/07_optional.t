use Test::More tests => 2;

ok( 1, 'One' );

SKIP: {
    eval { require Test::SharedFork };

    skip 'Test::SharedFork needed for tests', 1 if $@;

    ok( 2, 'Two' );
}

1;

