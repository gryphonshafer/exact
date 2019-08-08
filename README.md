# NAME

exact - Perl pseudo pragma to enable strict, warnings, features, mro, filehandle methods

# VERSION

version 1.08

[![Build Status](https://travis-ci.org/gryphonshafer/exact.svg)](https://travis-ci.org/gryphonshafer/exact)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/exact/badge.png)](https://coveralls.io/r/gryphonshafer/exact)

# SYNOPSIS

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
    use Carp qw( croak carp confess cluck );
    use Try::Tiny;

    no warnings "experimental::signatures";
    no warnings "experimental::refaliasing";
    no warnings "experimental::bitwise";

Type this:

    use exact;

Or for finer control, add some trailing modifiers like a line of the following:

    use exact '5.20';
    use exact 5.16, nostrict, nowarnings, noc3, noutf8, noexperiments, noautoclean;
    use exact noexperiments, fc, signatures;

# DESCRIPTION

[exact](https://metacpan.org/pod/exact) is a Perl pseudo pragma to enable strict, warnings, features, mro,
and filehandle methods. The goal is to reduce header boilerplate, assuming
defaults that seem to make sense but allowing overrides easily.

By default, [exact](https://metacpan.org/pod/exact) will:

- enable [strictures](https://metacpan.org/pod/strictures) (version 2)
- load the latest [feature](https://metacpan.org/pod/feature) bundle supported by the current Perl version
- load all experimental [feature](https://metacpan.org/pod/feature)s and switch off experimental warnings
- set C3 style of [mro](https://metacpan.org/pod/mro)
- use utf8 in the source code context and set STDIN, STROUT, and STRERR to handle UTF8
- enable methods on filehandles
- import [Carp](https://metacpan.org/pod/Carp)'s 4 methods
- import (kinda) [Try::Tiny](https://metacpan.org/pod/Try::Tiny)

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

This skips using [namespace::autoclean](https://metacpan.org/pod/namespace::autoclean).

## `nocarp`

This skips importing the 4 [Carp](https://metacpan.org/pod/Carp) methods: `croak`, `carp`, `confess`,
`cluck`.

## `notry`

This skips importing the functionality of [Try::Tiny](https://metacpan.org/pod/Try::Tiny).

# BUNDLES

You can always provide a list of explicit features and bundles from [feature](https://metacpan.org/pod/feature).
If provided, these will be enabled regardless of the other import flags set.

    use exact noexperiments, fc, signatures;

Bundles provided can be exactly like those described in [feature](https://metacpan.org/pod/feature) or in a
variety of obvious forms:

- :5.26
- 5.26
- v5.26
- 26

# METHODS

## `autoclean`

Normally, unless you include the `noautoclean` flag, [namespace::autoclean](https://metacpan.org/pod/namespace::autoclean)
will automatically clean your namespace. You can pass flags to autoclean via:

    exact->autoclean( -except => [ qw( method_a method_b) ] );

Note that for this to have any effect, it needs to be called from within your
module's `import` method.

# EXTENSIONS

It's possible to write extensions or plugins for [exact](https://metacpan.org/pod/exact) to provide
context-specific behavior, provided you are using Perl version 5.14 or newer.
To activate these extensions, you need to provide their named suffix as a
parameter to the `use` of [exact](https://metacpan.org/pod/exact).

    # will load "exact" and "exact::class";
    use exact class;

    # will load "exact" and "exact::role" and turn off UTF8 features;
    use exact role, noutf8;

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
        {
            no strict 'refs';
            *{ $caller . '::example' } = \&example;
        }
        exact->autoclean( -except => ['example'] );
    }

    sub example {
        say 42;
    }

    1;

# SEE ALSO

You can look for additional information at:

- [GitHub](https://github.com/gryphonshafer/exact)
- [CPAN](http://search.cpan.org/dist/exact)
- [MetaCPAN](https://metacpan.org/pod/exact)
- [AnnoCPAN](http://annocpan.org/dist/exact)
- [Travis CI](https://travis-ci.org/gryphonshafer/exact)
- [Coveralls](https://coveralls.io/r/gryphonshafer/exact)
- [CPANTS](http://cpants.cpanauthors.org/dist/exact)
- [CPAN Testers](http://www.cpantesters.org/distro/T/exact.html)

# AUTHOR

Gryphon Shafer <gryphon@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
