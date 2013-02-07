package Catmandu::Store::MongoDB;

use Catmandu::Sane;
use Moo;
use Catmandu::Store::MongoDB::Bag;
use MongoDB;

with 'Catmandu::Store';

=head1 NAME

Catmandu::Store::MongoDB - A Catmandu::Store plugin for MongoDB databases

=head1 VERSION

Version 0.0201

=cut

our $VERSION = '0.0201';

=head1 SYNOPSIS

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

=head1 DESCRIPTION

A Catmandu::Store::MongoDB is a Perl package that can store data into
MongoDB databases. The database as a whole is called a 'store'.
Databases also have compartments (e.g. tables) called Catmandu::Bag-s.

=head1 METHODS

=head2 new(database_name => $name )

Create a new Catmandu::Store::MongoDB store with name $name.

=head2 bag($name)

Create or retieve a bag with name $name. Returns a Catmandu::Bag.

=cut

my $CONNECTION_ARGS = [qw(
    host
    w
    wtimeout
    auto_reconnect
    auto_connect
    timeout
    username
    password
    db_name
    query_timeout
    max_bson_size
    find_master
)];

has connection    => (is => 'ro', lazy => 1, builder => '_build_connection');
has database_name => (is => 'ro', required => 1);
has database      => (is => 'ro', lazy => 1, builder => '_build_database');

sub _build_connection {
    MongoDB::Connection->new(delete $_[0]->{_args});
}

sub _build_database {
    my $self = $_[0]; $self->connection->get_database($self->database_name);
}

sub BUILD {
    my ($self, $args) = @_;
    $self->{_args} = {};
    for my $key (@$CONNECTION_ARGS) {
        $self->{_args}{$key} = $args->{$key} if exists $args->{$key};
    }
}

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
