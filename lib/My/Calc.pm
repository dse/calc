package My::Calc;
use warnings;
use strict;
use utf8;
use v5.14.0;                # required for srand() to return the seed.
use feature 'say';

our @IMPORTED;
our $INTERACTIVE = 0;

sub importeach (*@) {
    my $module = shift;
    eval "use $module;";
    return if $@;
    foreach my $symbol (@_) {
        my %before = do { no strict 'refs'; map { ($_ => 1) } keys %{__PACKAGE__ . '::'}; };
        eval { import $module $symbol; };
        my %after = do { no strict 'refs'; map { ($_ => 1) } keys %{__PACKAGE__ . '::'}; };
        if ($symbol =~ m{^:}) {
            my @new = grep { !exists($before{$_}) } keys %after;
            push(@IMPORTED, @new);
        } else {
            no strict 'refs';
            if (exists ${__PACKAGE__ . '::'}{$symbol}) {
                push(@IMPORTED, $symbol);
            }
        }
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

use Term::ReadLine;
use Text::Wrap qw(wrap);
use Data::Dumper qw(Dumper);

use lib '..';
use My::CalcTime;

sub new {
    my ($class) = @_;
    my $self = bless({}, $class);
    return $self;
}

our $__ = 0;

sub runInteractively {
    (my $self) = @_;
    my $term = Term::ReadLine->new('calc');
    my $prompt = 'calc> ';
    my $OUT = $term->OUT || \*STDOUT;
    local $_;
    while (defined ($_ = $term->readline($prompt))) {
        s{\R\z}{};
        my $result = $self->evalStringOrExpression($_);
        if (defined $result) {
            $__ = $result;
            say $result;
        }
    }
}

sub help () {
    print("\n");
    print("All built-in Perl math operators and functions are supported.\n");
    print("The following additional functions are supported:\n");
    print(wrap("    ", "    ", join(', ', @IMPORTED)), "\n");
    print("Use _ to refer to the value of the previous result.\n");
    print("\n");
    return;
}

sub _ () {
    return $__;
}

sub runCommandLine {
    (my $self, my @args) = @_;

    $INTERACTIVE = (-t 0 && -t 1 && !scalar @args);
    if ($INTERACTIVE) {
        $self->runInteractively();
    } elsif ($self->{asFilenames}) {
        $self->runMagicFilehandle(@args);
    } elsif (scalar @args) {
        foreach my $arg (@args) {
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
        my $result = $self->evalString($line);
        return $result;
    }
    my $result = $self->evalExpression($line);
    return $result;
}

# replace each occurrence of {...} in the string, return the result
#
# {<expr>}
# {<expr>#<format>}
# {<expr>=<result>}
# {<expr>=<result>#<format>}
sub evalString {
    my ($self, $line) = @_;
    $line =~ s{(?<pre>
                   (?<open>\{)
                   (?<openSpace>\s*)
                   (?:
                       (?<varPrefix>\$)
                       (?<varName>[A-Za-z_][A-Za-z_0-9]*)
                       (?<varEqual>\s*=\s*)
                   )?
               )
               (?<expr>[^{}=#]+?)
               (?<keeper>
                   (?<keepPre>\s*=\s*)
                   (?<keep>[^{}=#]*?)
               )?
               (?<post>
                   (?:
                       (?<formatPre>\s*\#\s*)
                       (?<format>[^{}#]*?)
                   )?
                   (?<closeSpace>\s*)
                   (?<close>\})
               )}
              {$self->evalExpressionString($+{expr}, %+)}geix;
    return $line;
}

sub evalExpressionString {
    # $exprString contains everything in the brackets
    #             but does not contain the brackets
    my ($self, $exprString, @args) = @_;

    if ($ENV{DEBUG}) {
        warn("$exprString @args\n");
    }

    my %args = @args;
    $args{original} = $exprString;
    if ($exprString =~ s{\#([^#]*)$}{}) {
        $args{format} = $1;
    }
    my $result = $self->evalExpression($exprString, %args);
    return $result;
}

our $NUM;
BEGIN {
    $NUM = qr{(?:\d+(?:\.\d*)?|\.\d+)};
}

sub evalExpression {
    my ($self, $expr, %args) = @_;
    # warn("evalExpression $expr\n");

    state %vars;

    # {3:1:5} => My::CalcTime->new('3:1:5');
    # warn("<< $expr\n");
    $expr =~ s{\(\s*
               (
                   ${NUM}?
                   (?:
                       \s*\:\s*${NUM}
                   )+
               )
               \s*\)}{My::CalcTime->new('$&')}gx;
    # warn(">> $expr\n");

    $expr =~ s{\N{MINUS SIGN}}{-}g;
    $expr =~ s{\N{MULTIPLICATION SIGN}}{*}g;
    $expr =~ s{\N{DIVISION SIGN}}{/}g;

    # $fooBar => $vars{fooBar}
    $expr =~ s{\$(?<ident>[A-Za-z_][A-Za-z_0-9]*)}
              {\$vars\{$+{ident}\}}gx;

    my $result = eval $expr;

    if ($INTERACTIVE) {
        if ($@) {
            warn($@);
        }
        return $result;
    }

    if ($@) {
        warn($@);
        if (defined $args{keep}) {
            return "$args{pre}$args{keeper}$args{post}";
        }
        return '';
    }
    if (!defined $result) {
        if (defined $args{keep}) {
            return "$args{pre}$args{keeper}$args{post}";
        }
        return '';
    }

    if (defined $args{varName}) {
        $vars{$args{varName}} = $result;
    }

    if (defined $args{format}) {
        $result = sprintf($args{format}, $result);
    } elsif (defined $self->{format}) {
        $result = sprintf($self->{format}, $result);
    }

    if (defined $args{keep}) {
        return "$args{pre}$args{expr}$args{keepPre}${result}$args{post}";
    }

    return $result;
}

1;
