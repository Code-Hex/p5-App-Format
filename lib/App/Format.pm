package App::Format;
use strict;
use warnings;
use Compiler::Lexer;

use String::CamelCase 'decamelize';
use App::Format::State;
use App::Format::Constants;
use Data::Dumper;

our $VERSION = "0.01";

my $brace_count = 0;
my $indent = "\t";

sub run {
    my @args = @_;
    my $filename = $args[1];

    open my $fh, '<', $filename or die "Cannot open $filename: $!";
    my $script = do { local $/; <$fh> };
    close $fh;

    my $lexer = Compiler::Lexer->new($filename);
    my $tokens = $lexer->tokenize($script);
    print Dumper $tokens;

    my $state = App::Format::State->new(indent => "    ");

    for (my $i = 0; $i < @$tokens; $i++) {
        my $token = $tokens->[$i];
        my $token_name = decamelize($token->name);
        if ($state->can($token_name)) {
            $state->$token_name($token);
        } else {
            $state->emit_data($token);
        }
    }
    $state->flush;

    return 0;
}


1;
__END__

=encoding utf-8

=head1 NAME

App::Format - It's new $module

=head1 SYNOPSIS

    use App::Format;

=head1 DESCRIPTION

App::Format is ...

=head1 LICENSE

Copyright (C) K.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

K E<lt>x00.x7f@gmail.comE<gt>

=cut

