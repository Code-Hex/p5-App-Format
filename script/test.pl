use strict;
  use warnings;

sub aaa {
    my $a = shift;
print $a;
}

sub bbb {
    my $b = shift;
    my $ccc = sub {
        my $x = shift;
print "Hello$x";
  print "world";
};
}

  print "Hello"x10;
print "End\n";