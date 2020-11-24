use strict;
use Test::More 'no_plan';

use Inline 'Prolog' => <<'CODE';
parent(john,sally).
parent(john,joe).
parent(mary,joe).
parent(phil,beau).
parent(jane,john).
grandparent(X,Z) :- parent(X,Y),parent(Y,Z).
CODE
    ;

{
    my $query = grandparent(\my $gparent, \my $gchild);
    ok $query->();
    is $gparent, 'jane';
    is $gchild,  'sally';

    ok $query->();
    is $gparent, 'jane';
    is $gchild,  'joe';

    is $query->(), undef, 'no more';
}


__END__



