package My::Calc::Functions;
use warnings;
use strict;

use POSIX qw(:math_h);
use POSIX qw(:math_h_c99);
use Math::Trig qw(:pi);
use Math::Trig qw(:radial);
use Math::Trig qw(:great_circle);

our @CALC_FUNCTIONS = (
    @{$POSIX::EXPORT_TAGS{math_h}},
    @{$POSIX::EXPORT_TAGS{math_h_c99}},
    @{$Math::Trig::EXPORT_TAGS{pi}},
    @{$Math::Trig::EXPORT_TAGS{radial}},
    @{$Math::Trig::EXPORT_TAGS{great_circle}},
);

use base "Exporter";
our @EXPORT = qw();
our @EXPORT_OK = (@CALC_FUNCTIONS, 'calc_functions');
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub calc_functions {
    return @CALC_FUNCTIONS;
}

1;
