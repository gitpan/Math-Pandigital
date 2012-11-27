#!/usr/bin/env perl
## no critic (eval)

use Test::More;

use strict;
use warnings;

BEGIN {
  my $status = eval 'use Math::Pandigital; 1;';
  diag "Test error: $@" if ! $status;
  ok( $status, 'use Math::Pandigital;' );
}


# Test Math::Pandigital::new with defaults.
{
  my $p = new_ok( 'Math::Pandigital' );
  is( $p->base,    10, 'base defaults to 10.'           );
  is( $p->unique,  0,  'unique defaults to true.'       );
  is( $p->zero,    1,  'zero indexed defaults to true.' );
  is_deeply( $p->_digits_array, [ 0 .. 9 ], '_digits_array defaults to 0..9' );
  is( ref($p->_digits_regexp), 'Regexp', '_digits_regexp returns a regex.' );
}


# Test Math::Pandigital::new with parameters.
{
  my $p = Math::Pandigital->new( base => 2, unique => 1, zero => 1 );
  is( $p->base,   2,
      'Setting base to 2 in constructor propagates to accessor.' );
  is( $p->unique, 1,
      'Setting unique to true in constructor propagates to accessor.' );
  is( $p->zero, 1,
      'Setting zero to true in constructor propagates to accessor.' );
  is( ref $p->_digits_regexp, 'Regexp',
      '_digits_charclass returned an RE object.' );
  like( $p->_digits_regexp, qr/\[01\]/, 'Base-2 creates a "[01]" character class.' );
  is_deeply( $p->_digits_array, [0..1], '_digits_array returns 0, 1 for base 2. ' );
}

# Basic test of Math::Pandigital::is_pandigital().
{
  my $p = Math::Pandigital->new;
  is( $p->is_pandigital( '1234567890' ),1,  '1234567890 is straight pandigital.' );
}

# Test new( zero => ... );
{
  my $p = Math::Pandigital->new( zero => 0 );
  is( $p->zero, 0, '1-based, base 10' );
  ok( ! $p->is_pandigital( '1234567890' ), 'zero cannot be a digit when zero=> 0' );
  ok( $p->is_pandigital('123456789'), 'zero=>0; 123456789 is pandigital.' );
  ok( $p->is_pandigital('1234567899'), 'zero=>0; 1234567899 (non-unique) is pandigital.' );
}

# Test out-of-bounds length:
{
  my $p = Math::Pandigital->new; # We need 10 digits.
  ok( ! $p->is_pandigital(123456), 'Not enough digits can not be pandigital.' );
}
{
  my $p = Math::Pandigital->new( unique => 1, base => 4 );
  ok( $p->is_pandigital( 1230 ), 'Base4, proper number of proper digits is pandigital.' );
  ok( ! $p->is_pandigital( 12330 ), 'Too many digits cannot be pandigital with unique.' );
}

# Test base<1, >10, !=16;
{
  ok( ! eval 'my $p = Math::Pandigital->new( base => 0 ); 1;', 'Base set <1 throws.' );
  ok( ! eval 'my $p = Math::Pandigital->new( base => 11 ); 1;', 'Base set >10 throws.' );
  ok( ! eval 'my $p = Math::Pandigital->new( base => 17 ); 1;', 'Base set >10 && != 16 throws.' );
  ok( eval 'my $p = Math::Pandigital->new( base => 1 ); 1;', 'Base 1 ok.' );
  ok( eval 'my $p = Math::Pandigital->new( base => 10 ); 1;', 'Base 10 ok.' );
  ok( eval 'my $p = Math::Pandigital->new( base => 16 ); 1;', 'Base 16 ok.' );
}

# Test pandigitality in base 16.
{
  my $p = Math::Pandigital->new( base => 16 );
  ok( $p->is_pandigital( '1234567890ABCDEF' ), 'Base 16 detects pandigitality.' );
  ok( ! $p->is_pandigital( '1234567890ABCDEE' ), 'Not pandigital (no F, two E)' );
  ok( $p->is_pandigital('1234567890aBcDeF'), 'Base 16 is case insensitive.' );
}

# Test pandigitality with repeats, and unique set.
{
  my $p = Math::Pandigital->new( unique => 1 );
  ok( ! $p->is_pandigital('12345678790'), 'unique set: Not pandigital if repeates, incorrect length.' );
  ok( $p->is_pandigital('1234567890'), 'unique set: Is pandigital if ... it is.' );
  ok( ! $p->is_pandigital('1234566890'), 'unique set: Not pandigital if repeats, correct length.' );
}

done_testing();
