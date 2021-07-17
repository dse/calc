package My::Calc;
use warnings;
use strict;
use utf8;
use v5.14.0;                # required for srand() to return the seed.
use feature 'say';

sub importeach (*@) {
    my $module = shift;
    eval "use $module;";
    return if $@;
    foreach my $symbol (@_) {
        eval { import $module $symbol; };
    }
}

BEGIN {
    importeach POSIX, qw(acos asin atan ceil cosh floor fmod frexp
                         ldexp log10 modf pow sinh tan tanh
                         acosh asinh atanh cbrt copysign expm1 fdim fma
                         fmax fmin hypot ilogb Inf j0 j1 jn y0 y1 yn
                         lgamma log1p log2 logb NaN nan nextafter
                         nexttoward remainder remquo round scalbn
                         tgamma trunc);
    importeach List::Util, qw(min max minn);
    importeach Math::Trig, qw(:pi);
}

use Term::Readline;

sub new {
    my ($class) = @_;
    my $self = bless({}, $class);
    return $self;
}

sub runInteractively {
    (my $self) = @_;
    my $term = Term::ReadLine->new('calc');
    my $prompt = 'calc> ';
    my $OUT = $term->OUT || \*STDOUT;
    local $_;
    while (defined ($_ = $term->readline($prompt))) {
        s{\R\z}{};
        say $self->evalStringOrExpression($_);
    }
}

sub runCommandLine {
    (my $self, my @args) = @_;

    if (-t 0 && -t 1 && !scalar @args) {
        $self->runInteractively();
    } elsif ($self->{asFilenames}) {
        $self->runMagicFilehandle(@args);
    } elsif (scalar @ARGV) {
        foreach my $arg (@ARGV) {
            say $self->evalExpression($arg);
        }
    } else {
        $self->runMagicFilehandle(@args);
    }
}

sub runMagicFilehandle {
    (my $self, local @ARGV) = @_;
    while (<>) {
        s{\R\z}{};
        say $self->evalString($_);
    }
}

sub runFilename {
    my ($self, $filename) = @_;
    my $fh;
    if (!open($fh, '<', $filename)) {
        warn("$filename: $!\n");
        return;
    }
    while (<$fh>) {
        s{\R\z}{};
        say $self->evalString($_);
    }
}

sub evalStringOrExpression {
    my ($self, $line) = @_;
    if ($line =~ m{\{.*\}}) {
        return $self->evalString($line);
    }
    return $self->evalExpression($line);
}

# replace each occurrence of {...} in the string, return the result
sub evalString {
    my ($self, $line) = @_;
    $line =~ s{(?<open>\{)
               (?<openSpace>\s*)
               (?<expr>[^\{\}]+?)
               (?<closeSpace>\s*)
               (?<close>\})}
              {$self->evalExpressionString($+{expr},
                                           open => $+{open},
                                           openSpace => $+{openSpace},
                                           closeSpace => $+{closeSpace},
                                           close => $+{close})}geix;
    return $line;
}

# <expr>
# <expr>#<format>
sub evalExpressionString {
    # $exprString contains everything in the brackets
    #             but does not contain the brackets
    my ($self, $exprString) = @_;

    my %args = (
        original => $exprString
    );

    if ($exprString =~ s{\#([^#]*)$}{}) {
        $args{format} = $1;
    }

    my $result = $self->evalExpression($exprString, %args);
}

sub evalExpression {
    my ($self, $expr, %args) = @_;

    $expr =~ s{\N{MINUS SIGN}}{-}g;
    $expr =~ s{\N{MULTIPLICATION SIGN}}{*}g;
    $expr =~ s{\N{DIVISION SIGN}}{/}g;

    my $result = eval $expr;

    if ($@) {
        warn($@);
        return undef;
    }
    if (!defined $result) {
        return undef;
    }

    if (defined $args{format}) {
        $result = sprintf($args{format}, $result);
    } elsif (defined $self->{format}) {
        $result = sprintf($self->{format}, $result);
    }

    return $result;
}

1;
