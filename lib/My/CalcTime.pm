package My::CalcTime;
use warnings;
use strict;

use Scalar::Util qw(looks_like_number);
use List::Util qw(all);
use POSIX qw(floor fmod);

# values can be subroutines, references to subroutines, or anonymous
# subroutines.
use overload (
    '""'   => \&tostring,
    '0+'   => \&tonumber,
    'bool' => \&tobool,
    '+'    => \&plus,
    '-'    => \&minus,
    '*'    => \&times,
    '/'    => \&divide,
    '%'    => \&mod,
    '+='   => \&plusAssign,
    '-='   => \&minusAssign,
    '*='   => \&timesAssign,
    '/='   => \&divideAssign,
    '%='   => \&modAssign,
    '<'    => \&lt,
    '>'    => \&gt,
    '=='   => \&eq,
    '<='   => \&le,
    '>='   => \&ge,
    '!='   => \&ne,
    'neg'  => \&unaryNeg,
    '!'    => \&unaryNot,
    'int'  => \&int,
);

sub new {
    my ($class, @from) = @_;
    my $self = bless({ value => 0 }, $class);
    $self->setFrom(@from) if scalar @from;
    return $self;
}

sub setFrom {
    my ($self, @from) = @_;
    if (scalar @from == 1) {
        my $from = $from[0];
        if (eval { $from->isa(__PACKAGE__) }) {
            $self->{value} = 0 + $from->{value};
            # warn(sprintf("%s => %s\n", dumper(\@from), $self->{value}));
            return;
        }
        if (looks_like_number($from)) {
            $self->{value} = $from;
            # warn(sprintf("%s => %s\n", dumper(\@from), $self->{value}));
            return;
        }
        if ($from =~ m{:}) {
            $from =~ s{^\s*\{\s*}{};
            $from =~ s{\s*\}\s*$}{};
            $from =~ s{^\s*\(\s*}{};
            $from =~ s{\s*\)\s*$}{};
            my @from2 = split(/\s*:\s*/, $from);
            $self->setFrom(@from2);
            # warn(sprintf("%s => %s\n", dumper(\@from), $self->{value}));
            return;
        }
    }
    if (all { looks_like_number($_) } @from) {
        if (scalar @from == 1) {
            $self->{value} = 0 + $from[0];
            # warn(sprintf("%s => %s\n", dumper(\@from), $self->{value}));
            return;
        }
        if (scalar @from == 2) {
            $self->{value} = $from[0] * 60 + $from[1];
            # warn(sprintf("%s => %s\n", dumper(\@from), $self->{value}));
            return;
        }
        if (scalar @from == 3) {
            $self->{value} = $from[0] * 3600 + $from[1] * 60 + $from[2];
            # warn(sprintf("%s => %s\n", dumper(\@from), $self->{value}));
            return;
        }
    }
    die(sprintf("invalid arguments: %s", dumper(\@from)));
}

sub tostring {
    my ($self) = @_;
    my $value = $self->{value};
    my $sign = '';
    if ($value < 0) {
        $sign = '-';
        $value = -$value;
    }
    if ($value < 3600) {
        return sprintf('%s(%02d:%02g)',
                       $sign,
                       floor($value / 60) % 60,
                       fmod($value, 60));
    }
    return sprintf('%s(%d:%02d:%02g)',
                   $sign,
                   floor($value / 3600),
                   floor($value / 60) % 60,
                   fmod($value, 60));
}
sub tonumber {
    my ($self) = @_;
    if (ref $self eq '') {
        return $self;
    }
    return $self->{value};
}
sub tobool {
    my ($self) = @_;
    return $self->{value} != 0;
}

sub plus {
    my ($self, $other, $swap) = @_;
    return __PACKAGE__->new(tonumber($self) + tonumber($other));
}
sub minus {
    my ($self, $other, $swap) = @_;
    return __PACKAGE__->new(tonumber($self) - tonumber($other));
}
sub times {
    my ($self, $other, $swap) = @_;
    return __PACKAGE__->new(tonumber($self) * tonumber($other));
}
sub divide {
    my ($self, $other, $swap) = @_;
    return __PACKAGE__->new(tonumber($self) / tonumber($other));
}
sub mod {
    my ($self, $other, $swap) = @_;
    return __PACKAGE__->new(tonumber($self) % tonumber($other));
}
sub lt {
    my ($self, $other, $swap) = @_;
    return tonumber($self) < tonumber($other);
}
sub gt {
    my ($self, $other, $swap) = @_;
    return tonumber($self) > tonumber($other);
}
sub eq {
    my ($self, $other, $swap) = @_;
    return tonumber($self) == tonumber($other);
}
sub le {
    my ($self, $other, $swap) = @_;
    return tonumber($self) <= tonumber($other);
}
sub ge {
    my ($self, $other, $swap) = @_;
    return tonumber($self) >= tonumber($other);
}
sub ne {
    my ($self, $other, $swap) = @_;
    return tonumber($self) != tonumber($other);
}
sub unaryNeg {
    my ($self) = @_;
    return __PACKAGE__->new(0 - $self->{value});
}
sub unaryNot {
    my ($self) = @_;
    return !tonumber($self);
}
sub int {
    my ($self) = @_;
    return __PACKAGE__->new(CORE::int(tonumber($self)));
}

use Data::Dumper qw(Dumper);
sub dumper {
    my ($value) = @_;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Terse = 1;
}

# unary            => 'neg ! ~ ~.',
# mutators         => '++ --',
# func             => 'atan2 cos sin exp abs log sqrt int',
# conversion       => 'bool "" 0+ qr',
# iterators        => '<>',
# filetest         => '-X',
# dereferencing    => '${} @{} %{} &{} *{}',
# matching         => '~~',
# special          => 'nomethod fallback ='

1;
