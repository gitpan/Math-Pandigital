package Math::Pandigital;

use Any::Moose;

use strict;
use warnings;

use Carp;

our $VERSION = '0.01';

has base   => ( is => 'ro', isa => 'Int',  default => sub { 10; } );
has unique => ( is => 'ro', isa => 'Bool', default => sub { 0;  } );
has zero   => ( is => 'ro', isa => 'Bool', default => sub { 1;  } );

has _digits_array => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  builder => '_build_digits_array'
);

has _digits_regexp => (
  is      => 'ro',
  isa     => 'RegexpRef',
  lazy    => 1,
  builder => '_build_digits_regexp'
);

has _min_length => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  builder => '_build_min_length'
);

sub BUILD {
  my $self = shift;
  croak "Base must be 1 .. 10, or 16"
    unless $self->base > 0 && ( $self->base <= 10 || $self->base == 16 );
  return;
}

sub _build_digits_array {
  my $self  = shift;
  my $start = $self->zero ? 0 : 1;
  my $base  = $self->base;
  my $set;
  if( $base <= 10 ) {                     # Base 1 .. 10.
    $set = [ $start .. $base - 1 ];
  }
  else {                                  # Base 16.
    $set = [ $start .. 9, 'A' .. 'F' ];
  }
  return $set;
}

sub _build_digits_regexp {
  my $self = shift;

  # Calculate the quantifier.
  my $min_length = $self->_min_length;
  my $quantifier = $self->unique ? "{$min_length}" : "{$min_length,}";

  # Compose a regex string with character class and quantifier.
  # Will look similar to "(?i:^[0123456789]{4,})", for example.
  my $re_str = join( '', '(?i:^[', @{ $self->_digits_array() }, "]$quantifier)\$" );
  # Turn it into a Regexp object and return.
  return qr/$re_str/;
}

sub _build_min_length {
  my $self = shift;

  # Calculate the minimum possible input length for $value to qualify.
  return $self->base - ( $self->zero ? 0 : 1 );
}

sub is_pandigital {
  my ( $self, $value ) = @_;

  return if not $self->_length_ok( $value );

  # The regexp test is done before we proceed to even more work.
  return if not $self->_chars_ok( $value );

  # Finally count individual digits to verify we have enough of each digit.
  return $self->_count_ok( $value );

}



sub _length_ok {
  my( $self, $value ) = @_;

  # Not pandigital if length is too short to contain all digits from base.
  my $min_length = $self->_min_length;
  return if length $value < $min_length;

  # Not pandigital if digits are unique, and length exceeds number
  # of base digits.
  return if $self->unique && length $value != $min_length;

  # Length seems fine.
  return 1;
}

sub _chars_ok {
  my( $self, $value ) = @_;

  # Reject if $value contains characters that are illegal for given base.
  my $re = $self->_digits_regexp;
  return $value =~ m/$re/; # Hex will be case-insensitive.
}

sub _count_ok {
  my( $self, $value ) = @_;
  
  # Count occurrences of each digit in $value.
  my %hash;
  for my $digit ( split //, uc $value ) {
    # If uniqueness is required, NOT pandigital if input has repeated digits.
    return if ++$hash{$digit} > 1 && $self->unique;
  }

  # Only pandigital if every digit in 'base' was touched at least once.
  return keys %hash == $self->_min_length;
}

__PACKAGE__->meta->make_immutable();
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Math::Pandigital - Pandigital number detection.

=head1 SYNOPSIS

    use Math::Pandigital;

    my $p = Math::Pandigital->new;
    my $test = 1234567890;
    if( $p->is_pandigital( $test ) ) {
      print "$test is pandigital.\n";
    }
    else {
      print $test is not pandigital.\n";
    }

    my $p = Math::Pandigital->new( base => 8, zero => 0, unique => 1 );
    print "012345567 is pandigital\n" if $p->is_pandigital('012345567'); # No.
    print "1234567 is pandigital\n" if $p->is_pandigital('1234567');     # Yes.
    
=head1 DESCRIPTION

A Pandigital number is an integer that contains at least one of each digit in its
base system.  For example, a base-2 pandigital number must contain both 0 and 1.
A base-10 pandigital number must contain 0, 1, 2, 3, 4, 5, 6, 7, 8, and 9.

Pandigital numbers usually include zero.  However, zeroless pandigital numbers,
containing (in base-10), 1 .. 9, and not 0 are sometimes permitted.

Additionally, some uses of pandigital numbers require that there be no repeated
digits.  In such a case, the base-2 number 01 would be pandigital, whereas 101
would not.

L<Math::Pandigital> provides a class that can be instantiated in any base, from
1 through 10, or 16 (hex), and can be used to detect pandigital numbers.  It may
also be configured to accept repeated digits, or to reject them, and to require
the 'zero' digit, or to reject it.

=head1 EXPORTS

No exports.

=head1 SUBROUTINES AND METHODS

=head2 new

    my $p = Math::Pandigital->new;

Constructs a Math::Pandigital test object.  If no parameters are passed, the
tests will assume base ten, requiring a "zero", and permitting repeated digits.

=head3 Optional constructor parameters

Any (or all) of the following parameters may optionally be used to configure the
test object.

=head4 base

    my $p = Math::Pandigital->new( base => 16 );

Set's the base to any value from 1 to 10, or 16.  If the goal is to detect
pandigitality of a binary number, select C<base => 2>, for example.  If not
specified, the default is base ten.  Common options are 2 (binary), 8 (octal),
10 (decimal), and 16 (hex), though 1 is permitted (unary), as is any value
between one and ten, inclusive.

For base-16 tests, the digits C<A .. F> will be tested case-insensitively.

=head4 unique

    my $p = Math::Pandigital->new( unique => 1 );

A Boolean flag used to set whether or not the pandigital number may contain
repeated digits.  For example, in base 2, with unique set, there are only two
pandigital numbers: 01, and 10.  With unique unset (the default), any binary
number of any length is permitted so long as it has at least one zero, and one
one.  The default is the traditional definition of a pandigital number: repeated
digits allowed.

=head4 zero

    my $p = Math::Pandigital->new( zero => 1 );

A Boolean flag.  The default is true.  When set (or the default accepted), the
pandigital number must include a zero.  When unset, the pandigital number may
not include a zero.

    my $p = Math::Pandigital->new( base => 4, zero => 0, unique => 1 );

The preceeding test would allow the following numbers to match:  123, 231, 213,
321, 312, and 132.  It would reject any number with a zero, or more (or less)
than three digits.

=head2 is_pandigital

    $p->is_pandigital($n);

C<$n> may be any string.  If the string contains only numeric digits that match
the criteria set forth when the test object is constructed, true is returned.
If the string contains any digits that aren't part of the base, or if it fails
to contain all necessary digits, or if it violates the uniqueness setting (if
set), it will return false.

Beware the possible traps and pitfalls.  Perl sees C<0123456789> as
C<123456789>, which may not be what you were expecting.  If there's a
possibility of a significant leadign zero, be sure to pass a string of digits
rather than a number.  C<is_pandigital> will silently stringify its target
before testing, but if an integer with a leading '0' is passed as a parameter,
the damage is done before C<is_pandigital> gets a chance to stringify it.

Another issue to consider: Pass hex as a string of hex digits, not as its native
C<0xNNNNNNNNNNNNNNNN> representation.  This is for two reasons.  First, a
16-digit hex number corresponds to 1.84467440737E+19, which loses significant
digits if passed numerically.  Second, we're simply not doing any conversions;
internally the string of digits is treated just as that, a I<string> of digits.

This is true of any base system.  It just works out better that way.

Remember that hex will be treated case-insensitively.

=head1 CAVEATS & WARNINGS

While any length of string of digits is permitted, there is no silver bullet;
the computational complexity of the C<is_pandigital()> test is linear in the
worst case.  In the best case, because length tests are carried out first,
any digit strings that violate the length requirements will be rejected in
constant time, without falling through to subsequent linear-time tests.

L<Math::Pandigital>'s test suite is currently at 99.0% coverage.

=head1 CONFIGURATION AND ENVIRONMENT

No special considerations.

=head1 DEPENDENCIES

Perl 5.6.2, and L<Any::Moose> are required.  Any::Moose will utilize either
Mouse, or Moose depending on your system and application's configuration.

=head1 INCOMPATIBILITIES

No known incompatibilities.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Pandigital_number>

=head1 AUTHOR

David Oswald C<< <davido at cpan dot org> >>

=head1 DIAGNOSTICS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Pandigital

This module is maintained in a public repo at Github. You may look for
information at:

=over 4

=item * Github: Development is hosted on Github at:

L<http://www.github.com/daoswald/Math-Pandigital>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Pandigital>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Pandigital>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Pandigital>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Pandigital/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 David Oswald.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

