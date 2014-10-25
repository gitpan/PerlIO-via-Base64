package PerlIO::via::Base64;

# Set the version info
# Make sure we do things by the book from now on

$VERSION = '0.05';
use strict;

# Make sure the encoding/decoding stuff is available

use MIME::Base64 (); # no need to pollute this namespace

# Set the default setting for the end of line character

my $eol = "\n";

# Satisfy -require-

1;

#-----------------------------------------------------------------------

# Class methods

#-----------------------------------------------------------------------

#  IN: 1 class (ignored)
#      2 new setting for eol (default: no change)
# OUT: 1 current setting for eol

sub eol {

# Set the new value if one specified
# Return whatever we have now

    $eol = $_[1] if @_ >1; 
    $eol;
} #eol

#-----------------------------------------------------------------------

# Methods for standard Perl features

#-----------------------------------------------------------------------
#  IN: 1 class
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { bless ['',$eol],$_[0] } #PUSHED

#-----------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)
#      2 handle to read from
# OUT: 1 decoded string

sub FILL {

# Make sure we slurp everything we can in one go
# Read the line from the handle
# Decode if there is something decode and return result or signal eof

    local $/;
    my $line = readline( $_[1] );
    (defined $line) ? MIME::Base64::decode_base64( $line ) : undef;
} #FILL

#-----------------------------------------------------------------------
#  IN: 1 instantiated object (reference to buffer)
#      2 buffer to be written
#      3 handle to write to (ignored)
# OUT: 1 number of bytes "written"

sub WRITE {

# Add to the buffer (encoding will take place on FLUSH)
# Return indicating we read the entire buffer

    $_[0]->[0] .= $_[1];
    length( $_[1] );
} #WRITE

#-----------------------------------------------------------------------
#  IN: 1 instantiated object (reference to buffer)
#      2 handle to write to
# OUT: 1 flag indicating error

sub FLUSH {

# If there is something in the buffer to be handled
#  Write out what we have in the buffer, encoding it on the fly
#  Reset the buffer
# Return indicating success

    if ($_[0]->[0]) {
        print {$_[1]} MIME::Base64::encode_base64( $_[0]->[0],$_[0]->[1] )
	 or return -1;
        $_[0]->[0] = '';
    }
    0;
} #FLUSH

#-----------------------------------------------------------------------
#  IN: class for which to import

sub import {

# Obtain the parameters
# Loop for all the value pairs specified

    my ($class,%param) = @_;
    $class->$_( $param{$_} ) foreach keys %param;
} #import

#-----------------------------------------------------------------------

__END__

=head1 NAME

PerlIO::via::Base64 - PerlIO layer for base64 (MIME) encoded strings

=head1 SYNOPSIS

 use PerlIO::via::Base64;
 PerlIO::via::Base64->eol( "\n" );  # default, write lines 76 bytes long
 PerlIO::via::Base64->eol( '' );    # no line endings, write one long string

 use PerlIO::via::Base64 eol => "\n";

 open( my $in,'<:via(Base64)','file.mime' )
  or die "Can't open file.mime for reading: $!\n";
 
 open( my $out,'>:via(Base64)','file.mime' )
  or die "Can't open file.mime for writing: $!\n";

=head1 DESCRIPTION

This module implements a PerlIO layer that works on files encoded in the
Base64 format (as described in RFC 2045).  It will decode from base64 format
while reading from a handle, and it will encode to base64 while writing to a
handle.

=head1 CLASS METHODS

There is one class method.  It can also be specified as a key value pair in
the C<use> statement.

=head2 eol

 use PerlIO::via::Base64 eol => '';

 PerlIO::via::Base64->eol( '' );   # no line endings, one long string
 open( my $out,'>:via(Base64)','file.mime' ); # no line endings

 $eol = PerlIO::via::Base64->eol;  # obtain current setting

MIME (Base64) encoded files can be written with line endings, causing all
lines (except the last) to be exactly 76 bytes long.  By default a linefeed
("\n") will be assumed.

Calling this class method with a new value will cause all subsequently opened
files to assume that new setting.  The eol value however is remembered within
the layer, so that it becomes part of the information that is associated with
that file.

If it were possible to pass parameters such as this to the layer while opening
the file, that would have been the approach taken.  Since that is not possible
yet, this way of doing it seems to be the next best thing.

=head1 CAVEAT

The current implementation slurps the whole contents of a handle into memory
before doing any encoding or decoding.  This may change in the future when I
finally figured out how READ and WRITE are supposed to work on incompletely
processed buffers.

=head1 SEE ALSO

L<PerlIO::via>, L<MIME::Base64> and any other PerlIO::via modules on CPAN.

=head1 COPYRIGHT

Copyright (c) 2002 Elizabeth Mattijsen.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
