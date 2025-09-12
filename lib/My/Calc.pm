package My::Calc;
use warnings;
use strict;
use Scalar::Util qw(looks_like_number);
use File::Basename qw(dirname);

use base "Exporter";
our @EXPORT = qw();
our @EXPORT_OK = qw(calc_evaluate);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $last_numeric_result = 0;
our $last_defined_result;
our $last_result;

use lib dirname(__FILE__) . "/../../lib";
use My::Calc::Functions qw(:all);

# prototype required for things like "_ + 5" to work
sub _ () {
    return $last_numeric_result;
}
sub __ () {
    return $last_defined_result;
}
sub ___ () {
    return $last_result;
}

sub calc_evaluate {
    my ($expr, $fmt) = @_;
    my $store_numeric_result = 1;
    my $store_defined_result = 0;
    my $store_any_result     = 0;

    if ($expr =~ s/^\s*#{3,}\s*//) {
        # ### store any result including undef
        $store_numeric_result = 1;
        $store_defined_result = 1;
        $store_any_result = 1;
    } elsif ($expr =~ s/^\s*#{2}\s*//) {
        # ## store any defined result
        $store_numeric_result = 1;
        $store_defined_result = 1;
        $store_any_result = 0;
    } elsif ($expr =~ s/^\s*#{1}\s*//) {
        # # don't restore
        $store_numeric_result = 0;
        $store_defined_result = 0;
        $store_any_result = 0;
    }

    if (looks_like_number($expr)) {
        if ($store_numeric_result || $store_defined_result || $store_any_result) {
            $last_numeric_result = $expr;
        }
        if (!defined $fmt) {
            return $expr;
        }
        return sprintf($fmt, $expr);
    }
    my $result = do {
        # no warnings;
        # no strict;
        eval($expr);
    };
    if (!defined $result) {
        if ($store_any_result) {
            $last_result = $expr;
        }
        return;
    }
    if (looks_like_number($result)) {
        if ($store_numeric_result) {
            $last_numeric_result = $result;
        }
        if ($store_defined_result) {
            $last_defined_result = $result;
        }
    }
    if (defined $fmt) {
        $result = sprintf($fmt, $result);
    }
    return $result;
}

1;
