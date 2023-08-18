package exact;
# ABSTRACT: Perl pseudo pragma to enable strict, warnings, features, mro, filehandle methods

use 5.014;
use strict;
use warnings;
use namespace::autoclean;
use Import::Into;
use Sub::Util 'set_subname';
use Syntax::Keyword::Try;

# VERSION

use feature    ();
use utf8       ();
use mro        ();
use Carp       qw( croak carp confess cluck );
use IO::File   ();
use IO::Handle ();
use Try::Tiny  ();

my ($perl_version) = $^V =~ /^v5\.(\d+)/;

my $features_available = ( %feature::feature_bundle and $feature::feature_bundle{all} )
    ? $feature::feature_bundle{all}
    : [ qw( say state switch unicode_strings ) ];

my $functions_available = [ qw(
    nostrict nowarnings
    nofeatures nobundle noskipexperimentalwarnings
    noutf8 noc3 nocarp notry trytiny noautoclean
) ];

my $functions_deprecated = ['noexperiments'];

my ( $no_parent, $late_parent );

sub import {
    my ( $self, $caller ) = ( shift, caller() );

    my ( @features, @nofeatures, @functions, @bundles, @classes );
    for (@_) {
        ( my $opt = $_ ) =~ s/^\-//;

        if ( grep { $_ eq $opt } @$features_available ) {
            push( @features, $opt );
        }
        elsif ( my ($nofeature) = grep { 'no' . $_ eq $opt } @$features_available ) {
            push( @nofeatures, $nofeature );
        }
        elsif ( grep { $_ eq $opt } @$functions_available, @$functions_deprecated ) {
            push( @functions, $opt ) if ( grep { $_ eq $opt } @$functions_available );
        }
        elsif ( $opt =~ /^:?v?5?\.?(\d+)/ and $1 >= 10 ) {
            push( @bundles, $1 );
        }
        else {
            push( @classes, $opt ) if ( $opt !~ /^no[a-z]{2}/ );
        }
    }

    strict  ->import unless ( grep { $_ eq 'nostrict'   } @functions );
    warnings->import unless ( grep { $_ eq 'nowarnings' } @functions );

    if (@bundles) {
        feature->import( ':5.' . $_ ) for (@bundles);
    }
    elsif (
        not grep { $_ eq 'nofeatures' } @functions and
        not grep { $_ eq 'nobundle'   } @functions
    ) {
        feature->import( $perl_version >= 16 ? ':all' : ':5.' . $perl_version );
    }
    feature->import($_)   for (@features);
    feature->unimport($_) for (@nofeatures);

    warnings->unimport('experimental')
        unless ( $perl_version < 18 or grep { $_ eq 'noskipexperimentalwarnings' } @functions );

    unless ( grep { $_ eq 'noutf8' } @functions ) {
        utf8->import;
        binmode( $_, ':utf8' ) for ( *STDIN, *STDERR, *STDOUT );
        'open'->import::into( $caller, ':std', ':utf8' );
    }

    mro::set_mro( $caller, 'c3' ) unless ( grep { $_ eq 'noc3' } @functions );

    monkey_patch( $self, $caller, ( map { $_ => \&{ 'Carp::' . $_ } } qw( croak carp confess cluck ) ) )
        unless ( grep { $_ eq 'nocarp' } @functions );

    feature->unimport('try') if (
        grep { $_ eq 'try' } @$features_available and
        (
            grep { $_ eq 'notry'   } @functions or
            grep { $_ eq 'trytiny' } @functions
        )
    );
    Syntax::Keyword::Try->import_into($caller) if (
        $perl_version < 36 and
        not grep { $_ eq 'notry'   } @functions and
        not grep { $_ eq 'trytiny' } @functions
    );
    eval qq{
        package $caller {
            use Try::Tiny;
        };
    } if ( grep { $_ eq 'trytiny' } @functions );

    my @late_parents = ();
    my $use          = sub {
        my ( $class, $pm, $caller, $params ) = @_;

        my $failed_require;
        try {
            require "$pm" unless ( do {
                no strict 'refs';
                no warnings 'once';
                ${"${caller}::INC"}{$pm};
            } );
        }
        catch {
            croak($@) unless ( index( $@, q{Can't locate } ) == 0 );
            return 0;
        }

        ( $no_parent, $late_parent ) = ( undef, undef );

        "$class"->import( $caller, @$params ) if ( "$class"->can('import') );

        if ($late_parent) {
            push( @late_parents, [ $class, $caller ] );
        }
        elsif ( not $no_parent and index( $class, 'exact::' ) != 0 ) {
            $self->add_isa( $class, $caller );
        }

        return 1;
    };
    for my $class (@classes) {
        my $params = ( $class =~ s/\(([^\)]+)\)// ) ? [$1] : [];
        ( my $pm = $class ) =~ s{::|'}{/}g;
        $pm .= '.pm';

        $use->(
            'exact::' . $class,
            'exact/' . $pm,
            $caller,
            $params,
        ) or $use->(
            $class,
            $pm,
            $caller,
            $params,
        ) or croak(
            "Can't locate exact/$pm or $pm in \@INC " .
            "(you may need to install the exact::$class or $class module)" .
            '(@INC contains: ' . join( ' ', @INC ) . ')'
        );
    }
    $self->add_isa(@$_) for @late_parents;

    namespace::autoclean->import( -cleanee => $caller ) unless ( grep { $_ eq 'noautoclean' } @functions );
}

sub monkey_patch {
    my ( $self, $class, %patch ) = @_;
    {
        no strict 'refs';
        no warnings 'redefine';
        *{"${class}::$_"} = set_subname( "${class}::$_", $patch{$_} ) for ( keys %patch );
    }
    return;
}

sub add_isa {
    my ( $self, $parent, $child ) = @_;
    {
        no strict 'refs';
        push( @{"${child}::ISA"}, $parent ) unless ( grep { $_ eq $parent } @{"${child}::ISA"} );
    }
    return;
}

sub no_parent {
    $no_parent = 1;
    return;
}

sub late_parent {
    $late_parent = 1;
    return;
}

sub _patch_import {
    my ( $type, $self, @names ) = @_;

    my $target          = ( caller(1) )[0];
    my $original_import = $target->can('import');

    my %groups;
    if ( $type eq 'provide' ) {
        %groups = map { %$_ } grep { ref $_ eq 'HASH' } @names;
        @names = grep { not ref $_ } @names;
    }

    monkey_patch(
        $self,
        $target,
        import => sub {
            my ( $package, @exports ) = @_;

            $original_import->(@_) if ($original_import);

            if ( $type eq 'force' ) {
                @exports = @names;
            }
            elsif ( $type eq 'provide' ) {
                @exports = grep { defined } map {
                    my $name = $_;

                    ( grep { $name eq $_ } @names ) ? $name                   :
                    ( exists $groups{$name}       ) ? ( @{ $groups{$name} } ) : undef;
                } @exports;
            }

            monkey_patch(
                $package,
                ( caller(0) )[0],
                map { $_ => \&{ $package . '::' . $_ } } @exports
            );

            return;
        },
    );
}

sub export {
    _patch_import( 'force', @_ );
    return;
}

sub exportable {
    _patch_import( 'provide', @_ );
    return;
}

1;
__END__
=pod

=begin :badges

=for markdown
[![test](https://github.com/gryphonshafer/exact/workflows/test/badge.svg)](https://github.com/gryphonshafer/exact/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/exact/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/exact)

=end :badges

=head1 SYNOPSIS

Instead of this:

    use strict;
    use warnings;
    use feature ':all';
    no warnings "experimental";
    use utf8;
    use open ':std', ':utf8';
    use mro 'c3';
    use IO::File;
    use IO::Handle;
    use Carp qw( croak carp confess cluck );
    use Syntax::Keyword::Try;
    use namespace::autoclean;

Type this:

    use exact;

Or for finer control, add some trailing modifiers like a line of the following:

    use exact -nofeatures, -signatures, -try, -say, -state;
    use exact 5.16, -nostrict, -nowarnings, -noc3, -noutf8, -noautoclean;
    use exact '5.20';

=head1 DESCRIPTION

L<exact> is a Perl pseudo pragma to enable strict, warnings, features, mro,
and filehandle methods along with a lot of other things, plus allow for easy
extension via C<exact::*> classes. The goal is to reduce header boilerplate,
assuming defaults that seem to make sense but allowing overrides easily.

By default, L<exact> will:

=for :list
* enable L<strictures> (version 2)
* enable all available L<feature>s and switch off experimental warnings
* use utf8 in the source code context and set STDIN, STROUT, and STRERR to handle UTF8
* set C3 style of L<mro>
* enable methods on filehandles
* import L<Carp>'s 4 methods
* implement a C<try...catch...finally> block solution based on Perl version

=head1 IMPORT FLAGS

L<exact> supports the following import flags:

=head2 C<nostrict>

This skips turning on the L<strict> pragma.

=head2 C<nowarnings>

This skips turning on the L<warnings> pragma.

=head2 C<nofeatures>

Normally, L<exact> will enable all available L<feature>s. Applying C<nofeatures>
causes this behavior to be skipped. You can still explicitly set features and/or
bundles.

=head2 C<noskipexperimentalwarnings>

Normally, L<exact> will disable experimental warnings. This skips that
disabling step.

=head2 C<noutf8>

This skips turning on UTF8 in the source code context. Also skips setting
STDIN, STDOUT, and STDERR to expect UTF8.

=head2 C<noc3>

This skips setting C3 L<mro>.

=head2 C<nocarp>

This skips importing the 4 L<Carp> methods: C<croak>, C<carp>, C<confess>,
C<cluck>.

=head2 C<notry>

This skips setting up C<try...catch...finally> support. This support is provided
either by the native Perl C<try> feature if available or else by importing the
functionality of L<Syntax::Keyword::Try> otherwise.

=head2 C<trytiny>

If you want to use L<Try::Tiny> instead of either native Perl's C<try> feature
or L<Syntax::Keyword::Try>, this is how.

=head2 C<noautoclean>

This skips using L<namespace::autoclean>.

=head1 BUNDLES

By default, the "all" bundle is enabled. You can skip this by including an
explicit bundle name or C<nofeatures>. You can enable and disable features.

    use exact -nofeatures, -signatures, -try, -say, -state;
    use exact 5.16, -nosay, -nostate;
    use exact '5.20';

Bundles provided can be exactly like those described in L<feature> or in a
variety of obvious forms:

=for :list
* :5.26
* 5.26
* v5.26
* 26

Note that bundles are exactly the same as what's in L<feature>, so for any
feature not part of a version bundle in L<feature>, you won't pick up that
feature with a bundle unless you explicitly declare the feature.

=head1 EXTENSIONS

It's possible to write extensions or plugins for L<exact> to provide
context-specific behavior, provided you are using Perl version 5.14 or newer.
To activate these extensions, you need to provide their named suffix as a
parameter to the C<use> of L<exact>.

    # will load "exact" and "exact::class";
    use exact -class;

    # will load "exact" and "exact::role" and turn off UTF8 features;
    use exact -role, -noutf8;

It's possible to provide parameters to the C<import> method of the extension.

    # will load "exact" and "exact::answer" and pass "42" to the import method
    use exact 'answer(42)';

=head2 Writing Extensions

An extension may but is not required to have an C<import> method. If such a
method does exist, it will be passed: the package name, the name of the caller
of L<exact>, and any parameters passed.

    package exact::example;
    use exact;

    sub import {
        my ( $self, $caller, $params ) = @_;
        exact->monkey_patch( $caller, 'example' => \&example );
    }

    sub example {
        say 42;
    }

    1;

=head1 PARENTS

You can use C<exact> to setup inheritance as follows:

    use exact 'SomeModule', 'SomeOtherModule';

This is roughly equivalent to:

    use exact;
    use parent 'SomeModule', 'SomeOtherModule';

See also the C<no_parent> method.

=head1 METHODS

=head2 C<monkey_patch>

Monkey patch functions into a given package.

    exact->monkey_patch( 'PackageName', add => sub { return $_[0] + $_[1] } );
    exact->monkey_patch(
        'PackageName',
        one   => sub { return 1 },
        two   => sub { return 2 },
        three => sub { return 3 },
    );

=head2 C<add_isa>

This method will add a given parent to the @ISA of a given child.

    exact->add_isa( 'SuperClassParent', 'SubClassChild' );

=head2 C<no_parent>

Normally, if you specify a parent, it'll be added as a parent by inclusion in
C<@INC>. If you don't want to skip C<@INC> inclusion, you can call C<no_parent>
in the C<import> of the module being specified as a parent.

    sub import {
        exact->no_parent;
    }

=head2 C<late_parent>

There may be a situation where you need an included parent to be listed last in
C<@INC> (at least relative to other parents). Normally, you'd do this by putting
the name last in the list of modules. However, if for some reason you can't do
that, you can call C<late_parent> from the C<import> of the parent that should
be delayed in C<@INC> inclusion.

    sub import {
        exact->late_parent;
    }

=head2 C<export>

This method performs work similar to using L<Exporter>'s C<@EXPORT>, but only
for methods. For a given method within your package, it will be exported to the
namespace that uses your package.

    exact->export( 'method', 'other_method' );

=head2 C<exportable>

This method performs work similar to using L<Exporter>'s C<@EXPORT_OK>, but only
for methods. For a given method within your package, it will be exported to the
namespace that uses your package.

    exact->exportable( 'method', 'other_method' );

It's possible to provide hashrefs as input to this method, and doing so provides
the means to setup groups of methods a consuming namespace can import.

    exact->exportable(
        'method',
        'other_method',
        {
            ':stuff' => [ qw( method other_method ) ],
            ':all'   => [ qw( method other_method some_additional_method ) ],
        }
    );

In the consuming namespace, you can then write:

    use YourPackage ':stuff'; # imports both "method" and "other_method"

=head1 SEE ALSO

You can look for additional information at:

=for :list
* L<GitHub|https://github.com/gryphonshafer/exact>
* L<MetaCPAN|https://metacpan.org/pod/exact>
* L<GitHub Actions|https://github.com/gryphonshafer/exact/actions>
* L<Codecov|https://codecov.io/gh/gryphonshafer/exact>
* L<CPANTS|http://cpants.cpanauthors.org/dist/exact>
* L<CPAN Testers|http://www.cpantesters.org/distro/T/exact.html>

=cut
