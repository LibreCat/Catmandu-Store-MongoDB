package Catmandu::Store::MongoDB::Searcher;
# TODO make a common Searcher role in Catmandu

use Catmandu::Sane;
use Carp qw(confess);
use Moo;

with 'Catmandu::Iterable';

has bag   => (is => 'ro', required => 1);
has query => (is => 'ro', required => 1);
has start => (is => 'ro', required => 1);
has limit => (is => 'ro', required => 1);
has total => (is => 'ro');
has sort  => (is => 'ro');

# look at search, generator methods of bag
sub generator {
    my ($self) = @_;
    confess "Not Implemented";
}

# copied from ElasticSearch implementation
sub slice { # TODO constrain total?
    my ($self, $start, $total) = @_;
    $start //= 0;
    $self->new(
        bag   => $self->bag,
        query => $self->query,
        start => $self->start + $start,
        limit => $self->limit,
        total => $total,
        sort  => $self->sort,
    );
}

# optimized version of Iterable search
# look at search method of bag
sub count {
    confess "Not Implemented";
}

1;
