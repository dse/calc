package My::CalcColor;
use warnings;
use strict;
use List::Util qw(max min);

use base "Exporter";

our @EXPORT = qw();
our @EXPORT_OK = qw(color_mix
                    clamp
                    srgb_to_hsl
                    hsl_to_srgb
                    srgb_to_linear
                    linear_to_srgb
                    linear_rgb_to_hsl
                    map_255_to_1
                    map_1_to_255
                    hsl_to_linear_rgb);
our %EXPORT_TAGS = (
    all => [@EXPORT_OK],
);

sub clamp {
    my ($x, $min, $max) = @_;
    return if !defined $x;
    if (!defined $min && !defined $max) {
        $min = 0;
        $max = 1;
    }
    return $min if defined $min && $x < $min;
    return $max if defined $max && $x > $max;
    return $x;
}

sub hexsrgb {
    my ($r, $g, $b) = @_;

    $r = round(clamp($r, 0, 255));
    $g = round(clamp($g, 0, 255));
    $b = round(clamp($b, 0, 255));
    return sprintf('#%02x%02x%02x', $r, $g, $b);
}

sub srgb_to_hsl {
    @_ = map { (ref $_ eq 'ARRAY') ? @$_ : ($_) } @_;

    my ($r, $g, $b) = @_;

    $r = clamp($r);
    $g = clamp($g);
    $b = clamp($b);

    ($r, $g, $b) = srgb_to_linear($r, $g, $b);
    my ($h, $s, $l) = linear_rgb_to_hsl($r, $g, $b);
    return ($h, $s, $l) if wantarray;
    return [$h, $s, $l];
}

sub hsl_to_srgb {
    @_ = map { (ref $_ eq 'ARRAY') ? @$_ : ($_) } @_;

    my ($h, $s, $l) = @_;

    while ($h < 0) { $h += 1; }
    while ($h > 1) { $h -= 1; }
    $s = clamp($s);
    $l = clamp($l);

    my ($r, $g, $b) = hsl_to_linear_rgb($h, $s, $l);
    ($r, $g, $b) = linear_to_srgb($r, $g, $b);
    return ($r, $g, $b) if wantarray;
    return [$r, $g, $b];
}

# https://en.wikipedia.org/wiki/SRGB
sub srgb_to_linear {
    @_ = map { (ref $_ eq 'ARRAY') ? @$_ : ($_) } @_;

    my @c = @_;

    @c = map { clamp($_) } @c;
    my @result = map {
        ($_ <= 0.04045) ? ($_ / 12.92) : ((($_ + 0.055) ** 2.4) / 1.055)
    } @c;
    return @result if wantarray;
    return [@result];
}

# https://en.wikipedia.org/wiki/SRGB
sub linear_to_srgb {
    @_ = map { (ref $_ eq 'ARRAY') ? @$_ : ($_) } @_;

    my @c = @_;

    @c = map { clamp($_) } @c;
    my @result = map {
        ($_ <= 0.0031308) ? (12.92 * $_) : (1.055 * ($_ ** (1 / 2.4)) - 0.055)
    } @c;
    return @result if wantarray;
    return [@result];
}

# given a color component in [0, 255],
# return a color component in [0, 1]
sub map_255_to_1 {
    if (ref $_[0] eq 'ARRAY') {
        my $aref = shift(@_);
        splice(@$aref, 3);
        unshift(@_, @$aref);
    }

    return map { clamp($_ / 255) } @_;
};                              # cperl

# given a color component in [0, 1],
# return a color component in [0, 255]
sub map_1_to_255 {
    if (ref $_[0] eq 'ARRAY') {
        my $aref = shift(@_);
        splice(@$aref, 3);
        unshift(@_, @$aref);
    }

    return map { round(clamp($_) * 255) } @_;
};                              # cperl

# ////////////////
# // RGB FUNCTIONS
# ////////////////
# node_modules/node-sass/src/libsass/src/functions.cpp

sub color_mix {
    @_ = map { (ref $_ eq 'ARRAY') ? @$_ : ($_) } @_;

    if (scalar @_ == 6 || scalar @_ == 7) {
        my ($r1, $g1, $b1, $r2, $g2, $b2, $p) = @_;

        $r1 = clamp($r1);
        $g1 = clamp($g1);
        $b1 = clamp($b1);
        $r2 = clamp($r2);
        $g2 = clamp($g2);
        $b2 = clamp($b2);
        $p = $p // 0.5;

        my $r = color_mix($r1, $r2, $p);
        my $g = color_mix($g1, $g2, $p);
        my $b = color_mix($b1, $b2, $p);
        return ($r, $g, $b) if wantarray;
        return [$r, $g, $b];
    }
    if (scalar @_ == 2 || scalar @_ == 3) {
        my ($c1, $c2, $p) = @_;
        $c1 = clamp($c1);
        $c2 = clamp($c2);
        $p = $p // 0.5;
        return clamp($p * $c1 + (1 - $p) * $c2);
    }
}

# ////////////////
# // HSL FUNCTIONS
# ////////////////

sub linear_rgb_to_hsl {
    if (ref $_[0] eq 'ARRAY') {
        my $aref = shift(@_);
        splice(@$aref, 3);
        unshift(@_, @$aref);
    }

    my ($r, $g, $b) = @_;

    $r = clamp($r);
    $g = clamp($g);
    $b = clamp($b);

    my $max = max($r, $g, $b);
    my $min = min($r, $g, $b);
    my $delta = $max - $min;
    my $h = 0;
    my $s;
    my $l = ($max + $min) / 2.0;
    if (near_equal($max, $min)) {
        $h = $s = 0;            # achromatic
    } else {
        if ($l < 0.5) {
            $s = $delta / ($max + $min);
        } else {
            $s = $delta / (2.0 - $max - $min);
        }
        if ($r == $max) {
            $h = ($g - $b) / $delta + ($g < $b ? 6 : 0);
        } elsif ($g == $max) {
            $h = ($b - $r) / $delta + 2;
        } elsif ($b == $max) {
            $h = ($r - $g) / $delta + 4;
        }
    }
    my @result = ($h / 6, $s, $l);
    return @result if wantarray;
    return [@result];
}

# hue to RGB helper function
sub h_to_rgb {
    @_ = map { (ref $_ eq 'ARRAY') ? @$_ : ($_) } @_;
    my ($m1, $m2, $h) = @_;
    while ($h < 0) {
        $h += 1;
    }
    while ($h > 1) {
        $h -= 1;
    }
    if ($h * 6.0 < 1) {         # h<1/6
        return $m1 + ($m2 - $m1) * $h * 6;
    }
    if ($h * 2.0 < 1) {         # h<1/2
        return $m2;
    }
    if ($h * 3.0 < 2) {         # h<2/3
        return $m1 + ($m2 - $m1) * (2.0 / 3.0 - $h) * 6;
    }
    return $m1;
}

sub hsl_to_linear_rgb {         # hsla_impl
    @_ = map { (ref $_ eq 'ARRAY') ? @$_ : ($_) } @_;

    my ($h, $s, $l) = @_;

    $l = clamp($l);
    $s = clamp($s);
    while ($h < 0) { $h += 1; }
    while ($h > 1) { $h -= 1; }
    # good so far

    if ($s == 0) {
        $s = 1e-10;
    }
    # good so far
    my $m2;
    if ($l <= 0.5) {
        $m2 = $l * ($s + 1.0);
    } else {
        $m2 = ($l + $s) - ($l * $s);
    }
    print("$m2\n");
    my $m1 = ($l * 2.0) - $m2;
    my $r = h_to_rgb($m1, $m2, $h + 1.0 / 3.0);
    my $g = h_to_rgb($m1, $m2, $h);
    my $b = h_to_rgb($m1, $m2, $h - 1.0 / 3.0);
    $r = clamp($r);
    $g = clamp($g);
    $b = clamp($b);
    return ($r, $g, $b) if wantarray;
    return [$r, $g, $b];
}

# to shift the hue, just add to or substract from $h.
# to brighten or darken, just add to or subtract from $l.
# to saturate or desaturate, just add to or subtract from $s.
# to grayscale, set $s to 0.
# to complement, add 0.5 to $h.
# to invert, take each rgb component and subtract it from 1.0.

sub scale_linear_rgb_component {
    my ($c, $scale) = @_;

    $c = clamp($c);

    return $c + $scale * ($scale > 0.0 ? 1 - $c : $c);
}

sub scale_linear_rgb {
    @_ = map { (ref $_ eq 'ARRAY') ? @$_ : ($_) } @_;

    my ($r, $g, $b, $scale) = @_;

    $r = clamp($r);
    $g = clamp($g);
    $b = clamp($b);

    ($r, $g, $b) = map { scale_linear_rgb_component($_, $scale) } ($r, $g, $b);
    return ($r, $g, $b) if wantarray;
    return [$r, $g, $b];
}

sub scale_h {
    my ($h, $scale) = @_;
    while ($h < 0) { $h += 1; }
    while ($h > 1) { $h -= 1; }
    return $h + $scale * ($scale > 0.0 ? 1 - $h : $h);
}

sub scale_s {
    my ($s, $scale) = @_;
    $s = clamp($s);
    return $s + $scale * ($scale > 0.0 ? 1 - $s : $s);
}

sub scale_l {
    my ($l, $scale) = @_;
    $l = clamp($l);
    return $l + $scale * ($scale > 0.0 ? 1 - $l : $l);
}

sub near_equal {
    my ($a, $b) = @_;
    return abs($a - $b) < 0.00000000000001;
}
