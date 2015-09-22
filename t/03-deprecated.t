#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use Catmandu::Store::MongoDB;

warnings_like {
    Catmandu::Store::MongoDB->new(
        database_name       => 'test',
        host                => 'mongodb://localhost:0',
        connect_retry       => 2,
        connect_retry_sleep => 2
    );
}
qr/are deprecated/i, 'warning for deprecated connection parameters';

done_testing;