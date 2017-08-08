package App::Format::Utils;

use strict;
use warnings;
use Carp 'croak';
use parent 'Exporter';

our @EXPORT = qw(slurp);

sub slurp {
    my $filename = shift;
    open my $fh, '<', $filename or croak "Could not open $filename: $!";
    my $script = do { local $/; <$fh> };
    close $fh;

    return $script;
}

1;