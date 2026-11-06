package My::Calc::Util;
use warnings;
use strict;

use base "Exporter";
our @EXPORT = qw();
our @EXPORT_OK = qw(separator_rx);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK
);

sub separator_rx {
    my ($value) = @_;
    if (!scalar @_) {
        die("missing parameter");
    }
    if ($value eq "") {
        die("cannot use empty string");
    }
    my $ref_type = ref $value;
    if ($ref_type eq "") {
        return quotemeta($_);
    }
    if ($ref_type eq "Regexp") {
        return $_;
    }
    if ($ref_type eq "ARRAY") {
        return "(?:" . join("|", map { config_val_to_regexp($_) } @$value) . ")";
    }
    die("invalid value type: ${ref_type}");
}

1;
