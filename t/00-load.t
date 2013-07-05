#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my @pkgs = qw(
    Catmandu::Store::MongoDB
    Catmandu::Store::MongoDB::Bag
    Catmandu::Store::MongoDB::Searcher
);

BEGIN {
  use_ok('Catmandu::Store::MongoDB');
  use_ok('Catmandu::Store::MongoDB::Bag');
  use_ok('Catmandu::Store::MongoDB::Searcher');
}

require_ok $_ for @pkgs;

my $data = [{
	_id => '1234',
	givenName => 'foo',
	familyName => 'bar',
	age => '21',
	location => 'europe',},
	{_id => '9876',
	givenName => 'Mongo',
	familyName => 'DB',
	location => 'europe',},
	];

my $bag = Catmandu::Store::MongoDB->new(database_name => 'test');

isa_ok($bag, 'Catmandu::Store::MongoDB');

foreach (qw(each add add_many get to_array delete delete_all)) {
	can_ok($bag, $_);
}

$bag->add_many($data);
my $rec = $bag->get('1234');
my $rec2 = $bag->get('9876');

is_deeply($data->[0], $rec);
is_deeply($data->[1], $rec2);
is($bag->count, 2);

$bag->delete('1234');
is($bag->count, 1);
isnt($bag->count, 2);

$bag->delete_all;
is($bag->count,0);

done_testing 20;