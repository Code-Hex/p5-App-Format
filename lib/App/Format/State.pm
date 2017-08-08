package App::Format::State;

use strict;
use warnings;
use Carp 'croak';
use Compiler::Lexer;
use App::Format::Constants;

use Data::Dumper;

sub slurp {
    my $filename = shift;
    open my $fh, '<', $filename or croak "Could not open $filename: $!";
    my $script = do { local $/; <$fh> };
    close $fh;

    return $script;
}

sub new {
    my $class = shift;
    my %args = @_;

    my $filename = $args{filename};
    my $script = slurp($filename);

    my $lexer = Compiler::Lexer->new($filename);
    my $tokens = $lexer->tokenize($script);
    print Dumper $tokens;

    return bless +{
        indent           => $args{indent},
        tokens           => $tokens,
        index            => 0,
        indent_flag      => 0,
        brace_count      => 0,
        looks_like_hash  => 0,
        formatted_buffer => [],
    }, $class;
}

sub string {
    my ($self, $token) = @_;
    my $str = $token->data;
    $self->emit_string($str);
}

sub comma {
    my ($self, $token) = @_;
    $self->emit_comma;
}

sub namespace {
    my ($self, $token) = @_;
    $self->emit_namespace($token->data);
}

sub namespace_resolver {
    my ($self, $token) = @_;
    $self->emit_namespace_resolver;
}

sub int {
    my ($self, $token) = @_;
    my $int = $token->data;
    $self->emit_number($int);
}

sub double {
    my ($self, $token) = @_;
    my $double = $token->data;
    $self->emit_number($double);
}

sub left_bracket {
    my ($self, $token) = @_;
    $self->brace_count++;
    $self->emit_left_bracket;
    $self->emit_newline;
    $self->emit_indent;
}

sub right_bracket {
    my ($self, $token) = @_;
    $self->brace_count--;
    $self->emit_indent;
    $self->emit_right_bracket;
}

sub left_brace {
    my ($self, $token) = @_;
    if ($self->is_hash) {
        $self->looks_like_hash++;
    }
    $self->indent_flag++;
    $self->brace_count++;
    $self->emit_left_brace;
    $self->emit_newline;
}

# }
sub right_brace {
    my ($self, $token) = @_;
    $self->brace_count--;
    $self->emit_indent;
    $self->emit_right_brace;
    if ($self->brace_count == 0) {
        my $index = $self->{index};
        if ($index < @{ $self->{tokens} }) {
            my $token = $self->{tokens}->[$index];
            if ($token->type == SEMI_COLON) {
                $self->emit_semi_colon;
                $self->{index}++;
            }
        }
        $self->emit_newline;
        $self->emit_newline;
    } else {
        if ($self->looks_like_hash) {
            # next token
            my $index = $self->{index};
            if ($index < @{ $self->{tokens} }) {
                my $token = $self->{tokens}->[$index];
                if ($token->type == COMMA
                || $token->type == RIGHT_BRACE
                || $token->type == RIGHT_PAREN) {
                    $self->looks_like_hash--;
                    $self->indent_flag--;
                }
            }
        } else {
            $self->emit_newline;
        }
    }
}

sub left_parenthesis {
    my ($self, $token) = @_;
    if ($self->is_hash) {
        $self->looks_like_hash++;
    }
    $self->emit_left_parenthesis;
}

sub right_parenthesis {
    my ($self, $token) = @_;
    $self->emit_right_parenthesis;
}

sub semi_colon {
    my $self = shift;
    $self->indent_flag++;

    my $src = $self->{formatted_buffer};
    if (1 < @$src && $src->[-2] eq "}") {
        pop @$src;
    }
    
    if (0 < @$src && $src->[-1] eq " ") {
        pop @$src;
    }
    $self->emit_semi_colon;
    $self->emit_newline;
}

# methods
sub fetch {
    my $self = shift;
    if ($self->{index} < @{ $self->{tokens} }) {
        return $self->{tokens}->[$self->{index}++];
    }
    return 0;
}

sub indent { $_[0]->{indent} }
sub indent_flag :lvalue { $_[0]->{indent_flag} }
sub brace_count :lvalue { $_[0]->{brace_count} }
sub looks_like_hash :lvalue { $_[0]->{looks_like_hash} }

sub is_hash {
    my ($self) = @_;
    my $index = $self->{index};
    if ($index + 1 < @{ $self->{tokens} }) {
        my $token = $self->{tokens}->[$index + 1];
        return $token->type == ARROW;
    }
    return 0;
}

# emit
sub emit_string {
    my ($self, $str) = @_;
    push @{ $self->{formatted_buffer} }, "\"$str\"";

    my $index = $self->{index};
    if ($index < @{ $self->{tokens} }) {
        my $type = $self->{tokens}->[$index]->type;
        if ($type == ARROW) {
            $self->emit_space;
        }
    }
}

sub emit_number {
    my ($self, $num) = @_;
    push @{ $self->{formatted_buffer} }, $num;

    my $index = $self->{index};
    if ($index < @{ $self->{tokens} }) {
        my $type = $self->{tokens}->[$index]->type;
        if ($type == ARROW) {
            $self->emit_space;
        }
    }
}

sub emit_left_bracket {
    my $self = shift;
    push @{ $self->{formatted_buffer} }, "[";
}

sub emit_right_bracket {
    my $self = shift;
    push @{ $self->{formatted_buffer} }, "]";
}

sub emit_left_brace {
    my $self = shift;
    push @{ $self->{formatted_buffer} }, "{";
}

sub emit_right_brace {
    my $self = shift;
    push @{ $self->{formatted_buffer} }, "}";
}

sub emit_left_parenthesis {
    my $self = shift;
    push @{ $self->{formatted_buffer} }, "(";
}

sub emit_right_parenthesis {
    my $self = shift;
    push @{ $self->{formatted_buffer} }, ")";
}

sub emit_newline {
    my $self = shift;
    push @{ $self->{formatted_buffer} }, "\n";
}

sub emit_semi_colon {
    my $self = shift;
    push @{ $self->{formatted_buffer} }, ";";
}

sub emit_indent {
    my $self = shift;
    push @{ $self->{formatted_buffer} }, $self->indent x $self->brace_count;
}

sub emit_data {
    my ($self, $token) = @_;

    if ($self->indent_flag) {
        $self->indent_flag--;
        $self->emit_indent;
    }
    push @{ $self->{formatted_buffer} }, $token->data;
    $self->emit_space;
}

sub emit_space {
    my $self = shift;
    push @{ $self->{formatted_buffer} }, " ";
}

sub emit_comma {
    my $self = shift;
    push @{ $self->{formatted_buffer} }, ",";

    my $is_brace;
    my $index = $self->{index};
    if ($index < @{ $self->{tokens} }) {
        my $type = $self->{tokens}->[$index]->type;
        $is_brace = $type == RIGHT_BRACE || $type == RIGHT_PAREN || $type == RIGHT_BRACKET;
    }

    if ($self->looks_like_hash) {
        $self->emit_newline;
        unless ($is_brace) {
            $self->emit_indent;
        }
    } else {
        $self->emit_space;
    }
}

sub emit_namespace {
    my ($self, $pkg) = @_;
    push @{ $self->{formatted_buffer} }, $pkg;

    my $index = $self->{index};
    if ($index < @{ $self->{tokens} }) {
        my $type = $self->{tokens}->[$index]->type;
        if ($type == LEFT_BRACE) {
            $self->emit_space;
        }
    }
}

sub emit_namespace_resolver {
    my $self = shift;
    push @{ $self->{formatted_buffer} }, "::";
}

sub flush {
    my $self = shift;
    print join '', @{ $self->{formatted_buffer} };
}

1;