# NAME

Catmandu::Store::MongoDB - A searchable store backed by MongoDB

# VERSION

Version 0.0301

# SYNOPSIS

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
    
    my $next_page = $hits->next_page;
    my $hits = $store->bag->search(query => '{"name":"Patrick"}' , page => $next_page);

    my $iterator = $store->bag->searcher(query => {name => "Patrick"});

# DESCRIPTION

A Catmandu::Store::MongoDB is a Perl package that can store data into
MongoDB databases. The database as a whole is called a 'store'.
Databases also have compartments (e.g. tables) called Catmandu::Bag-s.

# METHODS

## new(database\_name => $name , %opts )

Create a new Catmandu::Store::MongoDB store with name $name. Optionally provide
connection parameters (see MongoDB::MongoClient for possible options).

## bag($name)

Create or retieve a bag with name $name. Returns a Catmandu::Bag.

## client

Return the MongoDB::MongoClient instance.

## database

Return a MongoDB::Database instance.

# SEE ALSO

[Catmandu::Bag](https://metacpan.org/pod/Catmandu::Bag), [Catmandu::Searchable](https://metacpan.org/pod/Catmandu::Searchable) , [MongoDB::MongoClient](https://metacpan.org/pod/MongoDB::MongoClient)

# AUTHOR

Nicolas Steenlant, `<nicolas.steenlant at ugent.be>`

# LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
