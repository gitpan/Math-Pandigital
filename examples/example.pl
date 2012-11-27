#!/usr/bin/env perl

use strict;
use warnings;

use Math::Pandigital;

my $p = Math::Pandigital->new;

for( '1234567890' .. '9999999999' ) {
  print "$_ is pandigital\n" if $p->is_pandigital( $_ );
}
