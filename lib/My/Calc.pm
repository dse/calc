package My::Calc;
use warnings;
use strict;
use Scalar::Util qw(looks_like_number);
use File::Basename qw(dirname);

use base "Exporter";
our @EXPORT = qw();
our @EXPORT_OK = qw(calc_evaluate);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $last_result = 0;

use lib dirname(__FILE__) . "/../../lib";
use My::Calc::Functions qw(:all);

sub _ () {
    # prototype required for things like "_ + 5" to work
    return $last_result;
}

sub calc_evaluate {
    my ($expr, $fmt) = @_;
    my $store_last_result = 1;
    if ($expr =~ s/^\s*#\s*//) {
        $store_last_result = 0;
    }
    if (looks_like_number($expr)) {
        if ($store_last_result) {
            $last_result = $expr;
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
        return;
    }
    if (looks_like_number($result) && $store_last_result) {
        $last_result = $result;
    }
    if (defined $fmt) {
        $result = sprintf($fmt, $result);
    }
    return $result;
}

1;
