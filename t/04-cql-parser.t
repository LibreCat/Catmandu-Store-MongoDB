use strict;
use warnings;
use Test::More;
use Test::Exception;

require_ok "Catmandu::Store::MongoDB::CQL";

my $cql_mapping = +{
    default_relation => 'exact',
    default_index => "all",
    indexes => {
        all => {
            op => {
                '=' => 1,
                'exact' => 1,
                '<>' => 1,
                'any' => 1,
                'all' => 1,
                within => 1
            }
        },
        first_name => {
            op => {
                '=' => 1,
                'exact' => 1,
                '<>' => 1,
                'any' => 1,
                'all' => 1,
                within => 1
            }
        },
        last_name => {
            field => "ln",
            op => {
                '=' => 1,
                'exact' => 1,
                '<>' => 1,
                'any' => 1,
                'all' => 1,
                within => 1
            }
        },
        year => {
            op => {
                '=' => 1,
                exact => 1,
                '<>' => 1,
                '>' => 1,
                '<' => 1,
                '>=' => 1,
                '<=' => 1,
                'within' => { field => "year_i" }
            }
        }
    }
};

my $parser;

lives_ok(sub{
    $parser =  Catmandu::Store::MongoDB::CQL->new( mapping => $cql_mapping );
},"CQL parser created");

is_deeply(
    $parser->parse(qq(first_name = "Nicolas")),
    { first_name => "Nicolas" },
    "cql - term query - relation ="
);
#fails for some reason
#is_deeply(
#    $parser->parse(qq(first_name scr "Nicolas")),
#    { first_name => "Nicolas" },
#    "cql - term query - relation scr"
#);
is_deeply(
    $parser->parse(qq("Nicolas")),
    { all => "Nicolas" },
    "cql - term query - default index"
);
is_deeply(
    $parser->parse(qq(first_name <> "Nicolas")),
    { first_name => { '$ne' => "Nicolas" } },
    "cql - term query - <>"
);
is_deeply(
    $parser->parse(qq(first_name exact "Nicolas")),
    { first_name => "Nicolas" },
    "cql - term query - exact"
);
is_deeply(
    $parser->parse(qq(first_name any "a b c")),
    { first_name => { '$in' => [qw(a b c)] } },
    "cql - term query - any"
);
is_deeply(
    $parser->parse(qq(first_name any "^a b ^c^")),
    { first_name => { '$in' => [qr/^a/,"b",qr/^c$/] } },
    "cql - term query - any with wildcard"
);
is_deeply(
    $parser->parse(qq(first_name any/cql.unmasked "^a b ^c^")),
    { first_name => { '$in' => ["^a","b","^c^"] } },
    "cql - term query - any unmasked"
);

done_testing 9;
