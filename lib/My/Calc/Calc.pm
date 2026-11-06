package My::Calc::Calc;
use warnings;
use strict;
use utf8;

use File::Basename qw(dirname);
use Scalar::Util qw(looks_like_number);
use Data::Dumper qw();

use lib dirname(__FILE__) . "/../../../lib";
use My::Calc::Functions qw(:all);

use base "Exporter";

our @EXPORT = qw();
our @EXPORT_OK = qw($RX_START
                    $RX_EQ
                    $RX_FMT
                    $RX_END
                    $RX_IDENT
                    $RX_ASSIGN
                    $RX_CALC_TAG
                    eval_calc_tag);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK
);

our $RX_START  = qr{\{};
our $RX_EQ     = qr{=>?};
our $RX_FMT    = qr{\#+};
our $RX_END    = qr{\}};
our $RX_IDENT  = qr{\$[A-Za-z_][A-Za-z_0-9]*};
our $RX_ASSIGN = qr{:?=};

our $RX_CALC_TAG = qr{(?<start>${RX_START})
                      (?<part0_whole>
                          (?<space7>\s*)
                          (?<ident>${RX_IDENT})
                          (?<space8>\s*)
                          (?<ident>${RX_ASSIGN})
                      )?
                      (?<part1_whole>
                          (?<space1>\s*)
                          (?<expr>\S.*?)
                          (?<space2>\s*)
                      )
                      (?<part2_whole>
                          (?<eq>${RX_EQ})
                          (?<space3>\s*)
                          (?:
                              (?<old_result>\S.*?)
                          )?? (?# doubleplusungreedy for if "=" immed folwd by "#" )
                          (?<space4>\s*)
                      )?
                      (?<part3_whole>
                          (?<fmt_sep>${RX_FMT})
                          (?<space5>\s*)
                          (?:
                              (?<fmt>\S.*?)
                          )?
                          (?<space6>\s*)
                      )?
                      (?<end>${RX_END})}x;

# Replace the following tags:
#
#     { expr }
#     { expr = old result }
#     { expr = old result # %fmt }
#     { expr = # %fmt }
#     { $ident := expr }
#     { $ident := expr = old result }
#     { $ident := expr = old result # %fmt }
#     { $ident := expr = # %fmt }
#
# with appropriate results.
#
# DEVEL: always follor $G{space2} with // $G{space1}
#                              4                  3
#                              6                  5
sub eval_calc_tag {
    my ($match, %G) = @_;
    my $retval = "";
    my $result = eval_calc_str($G{expr}, $G{fmt}, $G{ident});

    my $space21;
    if (defined $G{space2}) {
        if ($G{space2} eq "") {
            $space21 = $G{space1};
        } else {
            $space21 = $G{space2};
        }
    }

    my $space43;
    if (defined $G{space4}) {
        if ($G{space4} eq "") {
            $space43 = $G{space3};
        } else {
            $space43 = $G{space4};
        }
    } else {
        $space43 = $space21;
    }

    $retval .= $G{start};
    $retval .= $G{part0_whole} if defined $G{part0_whole};
    $retval .= $G{part1_whole};
    $retval .= "=";
    $retval .= $space43;
    $retval .= $result // "";
    $retval .= $space43;
    $retval .= $G{part3_whole} if defined $G{part3_whole};
    $retval .= $G{end};
    return $retval;
}

our @numeric_results;
our @defined_results;
our @results;

# return a printed representation
sub eval_calc_str {
    my ($expr, $fmt, $ident) = @_;

    if ($expr eq "DUMP") {
        return dumper2(\@numeric_results);
    }

    my $eval_expr;
    if (defined $ident) {
        $eval_expr = $ident . " = " . $expr;
    } else {
        $eval_expr = $expr;
    }
    my $result = do {
        no strict "vars";
        eval($eval_expr);
    };
    push(@results, $result);
    push(@defined_results, $result) if defined $result;
    push(@numeric_results, $result) if defined $result && looks_like_number($result);
    if (looks_like_number($result)) {
        if (defined $fmt) {
            return sprintf($fmt, $result);
        } else {
            return $result;
        }
    } else {
        return dumper($result);
    }
}

sub _ {
    my $idx = shift() // 1;
    $idx = -abs($idx) + scalar @numeric_results;
    return scalar $numeric_results[$idx];
}

sub __ {
    my $idx = shift() // 1;
    $idx = -abs($idx) + scalar @defined_results;
    return scalar $defined_results[$idx];
}

sub ___ {
    my $idx = shift() // 1;
    $idx = -abs($idx) + scalar @results;
    return scalar $results[$idx];
}

sub dumper {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Indent = 0;
    return Data::Dumper::Dumper(@_);
}

sub dumper2 {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Indent = 1;
    return Data::Dumper::Dumper(@_);
}

1;
