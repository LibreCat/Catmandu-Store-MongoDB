# NAME

Catmandu::Store::MongoDB - A searchable store backed by MongoDB

# SYNOPSIS

    # On the command line
    $ catmandu import -v JSON --multiline 1 to MongoDB --database_name bibliography --bag books < books.json
    $ catmandu export MongoDB --database_name bibliography --bag books to YAML
    $ catmandu count MongoDB --database_name bibliography --bag books --query '{"PublicationYear": "1937"}'

    # In perl
    use Catmandu::Store::MongoDB;

    my $store = Catmandu::Store::MongoDB->new(database_name => 'test');

    my $obj1 = $store->bag->add({ name => 'Patrick' });

    printf "obj1 stored as %s\n" , $obj1->{_id};

    # Force an id in the store
    my $obj2 = $store->bag->add({ _id => 'test123' , name => 'Nicolas' });

    my $obj3 = $store->bag->get('test123');

    $store->bag->delete('test123');

    $store->bag->delete_all;

    # All bags are iterators
    $store->bag->each(sub { ... });
    $store->bag->take(10)->each(sub { ... });

    # Search
    my $hits = $store->bag->search(query => '{"name":"Patrick"}');
    my $hits = $store->bag->search(query => '{"name":"Patrick"}' , sort => { age => -1} );
    my $hits = $store->bag->search(query => {name => "Patrick"} , start => 0 , limit => 100);
    my $hits = $store->bag->search(query => {name => "Patrick"} , fields => {_id => 0, name => 1});

    my $next_page = $hits->next_page;
    my $hits = $store->bag->search(query => '{"name":"Patrick"}' , page => $next_page);

    my $iterator = $store->bag->searcher(query => {name => "Patrick"});
    my $iterator = $store->bag->searcher(query => {name => "Patrick"}, fields => {_id => 0, name => 1});

    # Catmandu::Store::MongoDB supports CQL...
    my $hits = $store->bag->search(cql_query => 'name any "Patrick"');

# DESCRIPTION

A Catmandu::Store::MongoDB is a Perl package that can store data into
[MongoDB](https://metacpan.org/pod/MongoDB) databases. The database as a whole is called a 'store'.
Databases also have compartments (e.g. tables) called Catmandu::Bag-s.

# METHODS

## new(database\_name => $name, %connectio\_opts)

## new(database\_name => $name , bags => { data => { cql\_mapping => $cql\_mapping } })

Create a new Catmandu::Store::MongoDB store with name $name. Optionally
provide connection parameters (see [MongoDB::MongoClient](https://metacpan.org/pod/MongoDB::MongoClient) for possible
options).

The store supports CQL searches when a cql\_mapping is provided. This hash
contains a translation of CQL fields into MongoDB searchable fields.

    # Example mapping
    $cql_mapping = {
        indexes => {
             title => {
               op => {
                 'any'   => 1 ,
                 'all'   => 1 ,
                 '='     => 1 ,
                 '<>'    => 1 ,
                 'exact' => {field => [qw(mytitle.exact myalttitle.exact)]}
               } ,
               sort  => 1,
               field => 'mytitle',
               cb    => ['Biblio::Search', 'normalize_title']
             }
       }
    }

The CQL mapping above will support for the 'title' field the CQL operators:
 any, all, =, <> and exact.

The 'title' field will be mapped into the MongoDB field 'mytitle',
except for the 'exact' operator. In case of 'exact' both the
'mytitle.exact' and 'myalttitle.exact' fields will be searched.

The CQL mapping allows for sorting on the 'title' field. If, for instance, we
would like to use a special MongoDB field for sorting we could have written
"sort => { field => 'mytitle.sort' }".

The CQL has an optional callback field 'cb' which contains a reference to subroutines
to rewrite or augment the search query. In this case, in the Biblio::Search package
contains a normalize\_title subroutine which returns a string or an ARRAY of string
with augmented title(s). E.g.

    package Biblio::Search;

    sub normalize_title {
       my ($self,$title) = @_;
       # delete all bad characters
       my $new_title =~ s{[^A-Z0-9]+}{}g;
       $new_title;
    }

    1;

## bag($name)

Create or retieve a bag with name $name. Returns a [Catmandu::Bag](https://metacpan.org/pod/Catmandu::Bag).

## client

Return the [MongoDB::MongoClient](https://metacpan.org/pod/MongoDB::MongoClient) instance.

## database

Return a [MongoDB::Database](https://metacpan.org/pod/MongoDB::Database) instance.

## drop

Delete the store and all it's bags.

# Search

Search the database: see [Catmandu::Searchable](https://metacpan.org/pod/Catmandu::Searchable). This module supports an additional search parameter:

    - fields => { <field> => <0|1> } : limit fields to return from a query (see L<MongoDB Tutorial|https://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>)

# SEE ALSO

[Catmandu::Bag](https://metacpan.org/pod/Catmandu::Bag), [Catmandu::Searchable](https://metacpan.org/pod/Catmandu::Searchable) , [MongoDB::MongoClient](https://metacpan.org/pod/MongoDB::MongoClient)

# AUTHOR

Nicolas Steenlant, `<nicolas.steenlant at ugent.be>`

# CONTRIBUTORS

Johann Rolschewski, `<jorol at cpan.org>`

# LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
