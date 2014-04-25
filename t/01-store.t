use strict;
use warnings;

use lib "t/lib";

use Test::More;
use Test::Exception;

use Catmandu::Store::MongoDB;

use MongoDBTest '$conn';

plan tests => 10;

ok $conn;

my $db = $conn->get_database('test_database');

my $store = Catmandu::Store::MongoDB->new(database_name => 'test_database');

ok $store;

my $obj1 = $store->bag->add({ _id => '123' , name => 'Patrick' });

ok $obj1;

is $obj1->{_id} , 123;

my $obj2 = $store->bag->get('123');

ok $obj2;

is_deeply $obj2 , { _id => '123' , name => 'Patrick'};

$store->bag->add({ _id => '456' , name => 'Nicolas' });

is $store->bag->count , 2;

is $store->bag->search(query => '{"name":"Nicolas"}')->total, 1;

$store->bag->delete('123');

is $store->bag->count , 1;

$store->bag->delete_all;

is $store->bag->count , 0;

END {
	if ($db) {
		$db->drop;
	}
}