# NAME

exact - Perl pseudo pragma to enable strict, warnings, features, mro, filehandle methods

# VERSION

version 1.17

[![test](https://github.com/gryphonshafer/exact/workflows/test/badge.svg)](https://github.com/gryphonshafer/exact/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/exact/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/exact)

# SYNOPSIS

Instead of this:

    use strict;
    use warnings;
    use utf8;
    use open ':std', ':utf8';
    use feature ':5.32';
    use feature qw( signatures refaliasing bitwise isa );
    no feature 'indirect';
    use mro 'c3';
    use IO::File;
    use IO::Handle;
    use namespace::autoclean;
    use Carp qw( croak carp confess cluck );
    use Syntax::Keyword::Try;

    no warnings "experimental::signatures";
    no warnings "experimental::refaliasing";
    no warnings "experimental::bitwise";

Type this:

    use exact;

Or for finer control, add some trailing modifiers like a line of the following:

    use exact -noexperiments, -fc, -signatures;
    use exact 5.16, -nostrict, -nowarnings, -noc3, -noutf8, -noautoclean;
    use exact '5.20';

# DESCRIPTION

[exact](https://metacpan.org/pod/exact) is a Perl pseudo pragma to enable strict, warnings, features, mro,
and filehandle methods along with a lot of other things, plus allow for easy
extension via `exact::*` classes. The goal is to reduce header boilerplate,
assuming defaults that seem to make sense but allowing overrides easily.

By default, [exact](https://metacpan.org/pod/exact) will:

- enable [strictures](https://metacpan.org/pod/strictures) (version 2)
- activate the latest [feature](https://metacpan.org/pod/feature) bundle supported by the current Perl version
- activate all experimental [feature](https://metacpan.org/pod/feature)s and switch off experimental warnings
- activate the `isa` feature (if Perl version is 5.32 or greater)
- deactivate the `indirect` feature
- set C3 style of [mro](https://metacpan.org/pod/mro)
- use utf8 in the source code context and set STDIN, STROUT, and STRERR to handle UTF8
- enable methods on filehandles
- import [Carp](https://metacpan.org/pod/Carp)'s 4 methods
- cause [Syntax::Keyword::Try](https://metacpan.org/pod/Syntax%3A%3AKeyword%3A%3ATry) to import its methods

# IMPORT FLAGS

[exact](https://metacpan.org/pod/exact) supports the following import flags:

## `nostrict`

This skips turning on the [strict](https://metacpan.org/pod/strict) pragma.

## `nowarnings`

This skips turning on the [warnings](https://metacpan.org/pod/warnings) pragma.

## `noutf8`

This skips turning on UTF8 in the source code context. Also skips setting
STDIN, STDOUT, and STDERR to expect UTF8.

## `noc3`

This skips setting C3 [mro](https://metacpan.org/pod/mro).

## `nobundle`

Normally, [exact](https://metacpan.org/pod/exact) will look at your current version and find the highest
supported [feature](https://metacpan.org/pod/feature) bundle and enable it. Applying `nobundle` causes this
behavior to be skipped. You can still explicitly set bundles yourself.

## `noexperiments`

This skips enabling all features currently labled experimental by [feature](https://metacpan.org/pod/feature).

## `noskipexperimentalwarnings`

Normally, [exact](https://metacpan.org/pod/exact) will disable experimental warnings. This skips that
disabling step.

## `noautoclean`

This skips using [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean).

## `nocarp`

This skips importing the 4 [Carp](https://metacpan.org/pod/Carp) methods: `croak`, `carp`, `confess`,
`cluck`.

## `notry`

This skips importing the functionality of [Syntax::Keyword::Try](https://metacpan.org/pod/Syntax%3A%3AKeyword%3A%3ATry).

## `trytiny`

If you want to use [Try::Tiny](https://metacpan.org/pod/Try%3A%3ATiny) instead of [Syntax::Keyword::Try](https://metacpan.org/pod/Syntax%3A%3AKeyword%3A%3ATry), this is how.
Note that if you specify both `trytiny` and `notry`, the latter will win.

## `noisa`

The `isa` feature is activated by default if the Perl version is 5.32 or
greater. If you want not that, specify `noisa`.

# BUNDLES

You can always provide a list of explicit features and bundles from [feature](https://metacpan.org/pod/feature).
If provided, these will be enabled regardless of the other import flags set.

    use exact -noexperiments, -fc, -signatures;

Bundles provided can be exactly like those described in [feature](https://metacpan.org/pod/feature) or in a
variety of obvious forms:

- :5.26
- 5.26
- v5.26
- 26

Note that bundles are exactly the same as what's in [feature](https://metacpan.org/pod/feature), so for any
feature not part of a version bundle in [feature](https://metacpan.org/pod/feature), you won't pick up that
feature with a bundle unless you explicitly declare the feature.

The exception to this is `isa`, which is available in Perl 5.32 and greater but
not included in the 5.32 bundle. However, `isa` is explicitly included if your
Perl version is 5.32 or greater unless you specify `noisa`.

Note also that the `indirect` feature is unimported by default, which is
counter to the non-exact default way, which is to import it. You can deunimport
`indirect` by explicitly specifying `indirect`.

# EXTENSIONS

It's possible to write extensions or plugins for [exact](https://metacpan.org/pod/exact) to provide
context-specific behavior, provided you are using Perl version 5.14 or newer.
To activate these extensions, you need to provide their named suffix as a
parameter to the `use` of [exact](https://metacpan.org/pod/exact).

    # will load "exact" and "exact::class";
    use exact -class;

    # will load "exact" and "exact::role" and turn off UTF8 features;
    use exact -role, -noutf8;

It's possible to provide parameters to the `import` method of the extension.

    # will load "exact" and "exact::answer" and pass "42" to the import method
    use exact 'answer(42)';

## Writing Extensions

An extension may but is not required to have an `import` method. If such a
method does exist, it will be passed: the package name, the name of the caller
of [exact](https://metacpan.org/pod/exact), and any parameters passed.

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

# PARENTS

You can use `exact` to setup inheritance as follows:

    use exact 'SomeModule', 'SomeOtherModule';

This is roughly equivalent to:

    use exact;
    use parent 'SomeModule', 'SomeOtherModule';

See also the `no_parent` method.

# METHODS

## `monkey_patch`

Monkey patch functions into a given package.

    exact->monkey_patch( 'PackageName', add => sub { return $_[0] + $_[1] } );
    exact->monkey_patch(
        'PackageName',
        one   => sub { return 1 },
        two   => sub { return 2 },
        three => sub { return 3 },
    );

## `add_isa`

This method will add a given parent to the @ISA of a given child.

    exact->add_isa( 'SuperClassParent', 'SubClassChild' );

## `no_parent`

Normally, if you specify a parent, it'll be added as a parent by inclusion in
`@INC`. If you don't want to skip `@INC` inclusion, you can call `no_parent`
in the `import` of the module being specified as a parent.

    sub import {
        exact->no_parent;
    }

## `late_parent`

There may be a situation where you need an included parent to be listed last in
`@INC` (at least relative to other parents). Normally, you'd do this by putting
the name last in the list of modules. However, if for some reason you can't do
that, you can call `late_parent` from the `import` of the parent that should
be delayed in `@INC` inclusion.

    sub import {
        exact->late_parent;
    }

## `export`

This method performs work similar to using [Exporter](https://metacpan.org/pod/Exporter)'s `@EXPORT`, but only
for methods. For a given method within your package, it will be exported to the
namespace that uses your package.

    exact->export( 'method', 'other_method' );

## `exportable`

This method performs work similar to using [Exporter](https://metacpan.org/pod/Exporter)'s `@EXPORT_OK`, but only
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

# SEE ALSO

You can look for additional information at:

- [GitHub](https://github.com/gryphonshafer/exact)
- [MetaCPAN](https://metacpan.org/pod/exact)
- [GitHub Actions](https://github.com/gryphonshafer/exact/actions)
- [Codecov](https://codecov.io/gh/gryphonshafer/exact)
- [CPANTS](http://cpants.cpanauthors.org/dist/exact)
- [CPAN Testers](http://www.cpantesters.org/distro/T/exact.html)

# AUTHOR

Gryphon Shafer <gryphon@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2021 by Gryphon Shafer.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
