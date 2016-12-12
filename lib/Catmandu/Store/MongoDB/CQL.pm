package Catmandu::Store::MongoDB::CQL;

use Catmandu::Sane;
use CQL::Parser;
use Carp qw(confess);
use Catmandu::Util qw(:is array_includes);
use Moo;

with 'Catmandu::Logger';

has parser  => (is => 'ro', lazy => 1, builder => '_build_parser');
has mapping => (is => 'ro');

my $any_field = qr'^(srw|cql)\.(serverChoice|anywhere)$'i;
my $match_all = qr'^(srw|cql)\.allRecords$'i;

sub _build_parser {
    CQL::Parser->new;
}

sub parse {
    my ($self, $query) = @_;
    my $node = eval {
        $self->parser->parse($query)
    } or do {
        my $error = $@;
        die "cql error: $error";
    };
    $self->visit($node);
}
sub visit {
    my ($self, $node) = @_;

    my $indexes = $self->mapping ? $self->mapping->{indexes} : undef;

    if ($node->isa('CQL::TermNode')) {

        my $term = $node->getTerm;

        if ($term =~ $match_all) {
            return +{};
        }

        my $qualifier = $node->getQualifier;
        my $relation  = $node->getRelation;
        my @modifiers = $relation->getModifiers;
        my $base      = lc $relation->getBase;
        my $m_search = {};
        my $search_field;
        my $search_clause;

        if ($base eq 'scr') {
            if ($self->mapping && $self->mapping->{default_relation}) {
                $base = $self->mapping->{default_relation};
            } else {
                $base = '=';
            }
        }

        #fields to search for
        if ($qualifier =~ $any_field) {
            #set default field explicitely
            if ( $self->mapping && $self->mapping->{default_index} ) {
                $search_field = $self->mapping->{default_index};
            }
            else {
                $search_field = '_all';
            }
        }else{

            $search_field = $qualifier;

            #change search field
            $search_field =~ s/(?<=[^_])_(?=[^_])//g if $self->mapping && $self->mapping->{strip_separating_underscores};
            my $q_mapping = $indexes->{$search_field} or confess "cql error: unknown index $search_field";
            $q_mapping->{op}->{$base} or confess "cql error: relation $base not allowed";

            my $op = $q_mapping->{op}->{$base};

            if (ref $op && $op->{field}) {

                $search_field = $op->{field};

            } elsif ($q_mapping->{field}) {

                $search_field = $q_mapping->{field};

            }

            #change term using filters
            my $filters;
            if (ref $op && $op->{filter}) {

                $filters = $op->{filter};

            } elsif ($q_mapping->{filter}) {

                $filters = $q_mapping->{filter};

            }
            if ($filters) {
                for my $filter (@$filters) {
                    if ($filter eq 'lowercase') {
                        $term = lc $term;
                    }
                }
            }

            #change term using callbacks
            if (ref $op && $op->{cb}) {
                my ($pkg, $sub) = @{$op->{cb}};
                $term = require_package($pkg)->$sub($term);
            } elsif ($q_mapping->{cb}) {
                my ($pkg, $sub) = @{$q_mapping->{cb}};
                $term = require_package($pkg)->$sub($term);
            }

        }

        #field search
        my $unmasked = array_includes([map { $_->[1] } @modifiers],"cql.unmasked");

        if ($base eq '=' or $base eq 'scr') {

            unless($unmasked){
                $term = _is_wildcard( $term ) ?
                    _wildcard_to_regex( $term ) :
                    $term;
            }
            $search_clause = +{ $search_field => $term };

        } elsif ($base eq '<') {

            $search_clause = +{ $search_field => { '$lt' => $term } };

        } elsif ($base eq '>') {

            $search_clause = +{ $search_field => { '$gt' => $term } };

        } elsif ($base eq '<=') {

            $search_clause = +{ $search_field => { '$lte' => $term } };

        } elsif ($base eq '>=') {

            $search_clause = +{ $search_field => { '$gte' => $term } };

        } elsif ($base eq '<>') {

            $search_clause = +{ $search_field => { '$ne' => $term } };

        } elsif ($base eq 'exact') {

            $search_clause = +{ $search_field => $term };

        } elsif ($base eq 'all') {

            my @terms = ( $term );
            unless($unmasked){
                @terms = map { _is_wildcard( $_ ) ? _wildcard_to_regex( $_ ) : $_ } split /\s+/, $term;
            }
            $search_clause = +{ $search_field => { '$all' => \@terms } };

        } elsif ($base eq 'any') {

            my @terms = ( $term );
            unless($unmasked){
                @terms = map { _is_wildcard( $_ ) ? _wildcard_to_regex( $_ ) : $_ } split /\s+/, $term;
            }
            $search_clause = +{ $search_field => { '$in' => [ split /\s+/, $term ] } };

        } elsif ($base eq 'within') {

            my @range = split /\s+/, $term;
            if (@range == 1) {
                $search_clause = +{ $search_field => $term };
            } else {
                $search_clause = +{
                    $search_field => {
                        '$gte' => $range[0],
                        '$lte' => $range[1]
                    }
                };
            }

        } else {

            unless($unmasked){
                $term = _is_wildcard( $term ) ?
                    _wildcard_to_regex( $term ) :
                    $term;
            }
            $search_clause = +{ $search_field => $term };

        }

        return $search_clause;

    }

    #TODO: apply cql_mapping
    elsif ($node->isa('CQL::ProxNode')) {
        confess "not supported";
    }

    elsif ($node->isa('CQL::BooleanNode')) {
        my $lft = $node->left;
        my $rgt = $node->right;
        my $lft_q = $self->visit($lft);
        my $rgt_q = $self->visit($rgt);
        my $op = '$'.lc( $node->op );

        if( $op eq '$and' || $op eq '$or' ){

            return +{ $op => [ $lft_q, $rgt_q ] };

        }
        elsif( $op eq '$not' ){

            my($k,$v) = each(%$rgt_q);
            if( $k eq '$or' ){

                return +{ %$lft_q, '$nor' => $v };

            }
            elsif( $k eq '$and' ){

                #$nand not implemented yet (https://jira.mongodb.org/browse/SERVER-15577)
                return +{ %$lft_q, '$nor' => [{
                    '$and' => $v
                }] };

            }else{

                return +{ %$lft_q, '$nor' => [{
                    '$and' => [{ $k => $v }]
                }] };

            }

        }
    }
}
sub _is_wildcard {
    my $value = $_[0];
    (index($value,'^') == 0) || (rindex($value,'^') == length($value) - 1) || (index($value,'*') >= 0) || (index($value,'?') >= 0);
}
sub _wildcard_to_regex {
    my $value = $_[0];
    my $regex = $value;
    $regex =~ s/\*/.*/go;
    $regex =~ s/\?/.?/go;
    $regex =~ s/\^$/\$/o;
    qr/$regex/;
}

1;

=head1 NAME

Catmandu::Store::MongoDB::CQL - Converts a CQL query string to a MongoDB query string

=head1 SYNOPSIS

    $mongo_query_string = Catmandu::Store::MongoDB::CQL->parse($cql_query_string);

=head1 DESCRIPTION

This package currently parses most of CQL 1.1:

    and
    or
    not
    srw.allRecords
    srw.serverChoice
    srw.anywhere
    cql.allRecords
    cql.serverChoice
    cql.anywhere
    =
    scr
    <
    >
    <=
    >=
    <>
    exact
    all
    any
    within

=head1 METHODS

=head2 parse

Parses the given CQL query string with L<CQL::Parser> and converts it to a Mongo query string.

=head2 visit

Converts the given L<CQL::Node> to a Mongo query string.

=head1 REMARKS

no support for fuzzy search, search modifiers, sortBy and encloses

=head1 SEE ALSO

L<CQL::Parser>.

=cut
