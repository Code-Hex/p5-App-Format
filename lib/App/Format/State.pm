package App::Format::State;

use Moo;

my @src;
my $brace_count = 0;

has indent => (is  => 'ro');
has indent_flag => (is => 'rw', default => 0);

sub string {
    my ($self, $token) = @_;
    my $str = $token->data;
    push @src, "\"$str\"";
}

sub left_brace {
    my ($self, $token) = @_;
    $self->indent_flag(1);
    $self->brace_count++;
    $self->emit_left_brace;
    $self->emit_newline;
}

sub right_brace {
    my ($self, $token) = @_;
    $self->brace_count--;
    $self->emit_indent;
    $self->emit_right_brace;
    if ($self->brace_count == 0) {
        $self->emit_newline;
        $self->emit_newline;
    } else {
        $self->emit_newline;
    }
}

sub semi_colon {
    my $self = shift;
    $self->indent_flag(1);

    if (1 < @src && $src[-2] eq "}") {
        pop @src;
    }
    
    if (0 < @src && $src[-1] eq " ") {
        pop @src;
    }
    $self->emit_semi_colon;
    $self->emit_newline;
}

# methods

sub brace_count :lvalue {
    my $self = shift;
    $brace_count;
}

sub emit_left_brace {
    my $self = shift;
    push @src, "{";
}

sub emit_right_brace {
    my $self = shift;
    push @src, "}";
}

sub emit_newline {
    my $self = shift;
    push @src, "\n";
}

sub emit_semi_colon {
    my $self = shift;
    push @src, ";";
}

sub emit_indent {
    my $self = shift;
    push @src, $self->indent x $self->brace_count;
}

sub emit_data {
    my ($self, $token) = @_;
    if ($self->indent_flag) {
        $self->indent_flag(0);
        $self->emit_indent;
    }
    push @src, $token->data;
    push @src, " ";
}

sub flush {
    my $self = shift;
    print join '', @src;
}

__PACKAGE__->meta->make_immutable;

1;