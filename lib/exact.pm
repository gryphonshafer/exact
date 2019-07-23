package exact;
# ABSTRACT: Perl pseudo pragma to enable strict, warnings, features, mro, filehandle methods

use 5.010;
use strict;
use warnings;
use namespace::autoclean;

# VERSION

use feature    ();
use utf8       ();
use mro        ();
use IO::File   ();
use IO::Handle ();
use Carp       'croak';

my %features = (
    10 => [ qw( say state switch ) ],
    12 => ['unicode_strings'],
    16 => [ qw( unicode_eval evalbytes current_sub fc ) ],
    18 => ['lexical_subs'],
    24 => [ qw( postderef postderef_qq ) ],
    28 => ['bitwise'],
);

my %deprecated = (
    16 => ['array_base'],
);

my %experiments = (
    20 => ['signatures'],
    22 => ['refaliasing'],
    26 => ['declared_refs'],
);

my @function_list = qw(
    nostrict nowarnings noutf8 noc3 nobundle noexperiments noskipexperimentalwarnings noautoclean
);

my @feature_list   = map { @$_ } values %features, values %deprecated, values %experiments;
my ($perl_version) = $^V =~ /^v5\.(\d+)/;

sub import {
    shift;
    my ( @bundles, @functions, @features );
    for (@_) {
        my $opt = lc $_;

        if ( grep { $_ eq $opt } @feature_list ) {
            push( @features, $opt );
        }
        elsif ( grep { $_ eq $opt } @function_list ) {
            push( @functions, $opt );
        }
        elsif ( $opt =~ /^:?v?5?\.?(\d+)/ and $1 >= 10 ) {
            push( @bundles, $1 );
        }
        else {
            my $v = __PACKAGE__->VERSION;
            croak( qq{"$opt" is not supported by exact} . ( ($v) ? ' ' . $v : '' ) );
        }
    }

    strict->import unless ( grep { $_ eq 'nostrict' } @functions );
    warnings->import unless ( grep { $_ eq 'nowarnings' } @functions );

    unless ( grep { $_ eq 'noutf8' } @functions ) {
        utf8->import;
        binmode( $_, ':utf8' ) for ( *STDIN, *STDERR, *STDOUT );
    }

    mro::set_mro( scalar caller(), 'c3' ) unless ( grep { $_ eq 'noc3' } @functions );
    namespace::autoclean->import( '-cleanee' => scalar caller() )
        unless ( grep { $_ eq 'noautoclean' } @functions ) ;

    if (@bundles) {
        my ($bundle) = sort { $b <=> $a } @bundles;
        feature->import( ':5.' . $bundle );
    }
    elsif ( not grep { $_ eq 'nobundle' } @functions ) {
        feature->import( ':5.' . $perl_version );
    }

    eval {
        feature->import($_) for (@features);
        my @experiments = map { @{ $experiments{$_} } } grep { $_ <= $perl_version } keys %experiments;
        feature->import(@experiments) unless ( not @experiments or grep { $_ eq 'noexperiments' } @functions );
    };
    if ( my $err = $@ ) {
        $err =~ s/\s*at .+? line \d+\.\s+//;
        croak("$err via use of exact");
    }

    warnings->unimport('experimental')
        unless ( $perl_version < 18 or grep { $_ eq 'noskipexperimentalwarnings' } @functions );
}

1;
__END__
=pod

=begin :badges

=for markdown
[![Build Status](https://travis-ci.org/gryphonshafer/exact.svg)](https://travis-ci.org/gryphonshafer/exact)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/exact/badge.png)](https://coveralls.io/r/gryphonshafer/exact)

=end :badges

=head1 SYNOPSIS

Instead of this:

    use strict;
    use warnings;
    use utf8;
    use open ':std', ':utf8';
    use feature ':5.23';
    use feature qw( signatures refaliasing bitwise );
    use mro 'c3';
    use IO::File;
    use IO::Handle;
    use namespace::autoclean;

    no warnings "experimental::signatures";
    no warnings "experimental::refaliasing";
    no warnings "experimental::bitwise";

Type this:

    use exact;

Or for finer control, add some trailing modifiers like a line of the following:

    use exact '5.20';
    use exact 5.16, nostrict, nowarnings, noc3, noutf8, noexperiments, noautoclean;
    use exact noexperiments, fc, signatures;

=head1 DESCRIPTION

L<exact> is a Perl pseudo pragma to enable strict, warnings, features, mro,
and filehandle methods. The goal is to reduce header boilerplate, assuming
defaults that seem to make sense but allowing overrides easily.

By default, L<exact> will:

=for :list
* enable L<strictures> (version 2)
* load the latest L<feature> bundle supported by the current Perl version
* load all experimental L<feature>s and switch off experimental warnings
* set C3 style of L<mro>
* use utf8 in the source code context
* enable methods on filehandles

=head1 IMPORT FLAGS

L<exact> supports the following import flags:

=head2 C<nostrict>

This skips turning on the L<strict> pragma.

=head2 C<nowarnings>

This skips turning on the L<warnings> pragma.

=head2 C<noutf8>

This skips turning on UTF8 in the source code context. Also skips setting
STDIN, STDOUT, and STDERR to expect UTF8.

=head2 C<noc3>

This skips setting C3 L<mro>.

=head2 C<nobundle>

Normally, L<exact> will look at your current version and find the highest
supported L<feature> bundle and enable it. Applying C<nobundle> causes this
behavior to be skipped. You can still explicitly set bundles yourself.

=head2 C<noexperiments>

This skips enabling all features currently labled experimental by L<feature>.

=head2 C<noskipexperimentalwarnings>

Normally, L<exact> will disable experimental warnings. This skips that
disabling step.

=head2 C<noautoclean>

This skips using L<namespace::autoclean>.

=head2 Explicit Features and Bundles by Name

You can always provide a list of explicit features and bundles from L<feature>.
If provided, these will be enabled regardless of the other import flags set.

    use exact noexperiments, fc, signatures;

Bundles provided can be exactly like those described in L<feature> or in a
variety of obvious forms:

=for :list
* :5.26
* 5.26
* v5.26
* 26

=head1 SEE ALSO

You can look for additional information at:

=for :list
* L<GitHub|https://github.com/gryphonshafer/exact>
* L<CPAN|http://search.cpan.org/dist/exact>
* L<MetaCPAN|https://metacpan.org/pod/exact>
* L<AnnoCPAN|http://annocpan.org/dist/exact>
* L<Travis CI|https://travis-ci.org/gryphonshafer/exact>
* L<Coveralls|https://coveralls.io/r/gryphonshafer/exact>
* L<CPANTS|http://cpants.cpanauthors.org/dist/exact>
* L<CPAN Testers|http://www.cpantesters.org/distro/T/exact.html>

=cut
