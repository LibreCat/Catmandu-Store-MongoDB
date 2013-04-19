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

sub generator {
    my ($self) = @_;
    sub {
        state $cursor = do {
            my $c = $self->bag->collection->find($self->query);
            # limit is unused because the perl driver doesn't expose batchSize
            $c->limit($self->total) if defined $self->total;
            $c->sort($self->sort) if defined $self->sort;
            $c;
        };
        $cursor->next;
    };
}

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


sub count { # TODO constrain on start, total?
    my ($self) = @_;
    $self->bag->collection->count($self->query);
}

1;
