# NAME

exact - Perl pseudo pragma to enable strict, warnings, features, mro, filehandle methods

# VERSION

version 1.05

[![Build Status](https://travis-ci.org/gryphonshafer/exact.svg)](https://travis-ci.org/gryphonshafer/exact)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/exact/badge.png)](https://coveralls.io/r/gryphonshafer/exact)

# SYNOPSIS

Instead of this:

    use strict;
    use warnings;
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
    use exact qw( 5.16 nostrict nowarnings noc3 noexperiments noautoclean );
    use exact qw( noexperiments fc signatures );

# DESCRIPTION

[exact](https://metacpan.org/pod/exact) is a Perl pseudo pragma to enable strict, warnings, features, mro,
and filehandle methods. The goal is to reduce header boilerplate, assuming
defaults that seem to make sense but allowing overrides easily.

By default, [exact](https://metacpan.org/pod/exact) will:

- enable [strictures](https://metacpan.org/pod/strictures) (version 2)
- load the latest [feature](https://metacpan.org/pod/feature) bundle supported by the current Perl version
- load all experimental [feature](https://metacpan.org/pod/feature)s and switch off experimental warnings
- set C3 style of [mro](https://metacpan.org/pod/mro)
- enable methods on filehandles

# IMPORT FLAGS

[exact](https://metacpan.org/pod/exact) supports the following import flags:

## `nostrict`

This skips turning on the [strict](https://metacpan.org/pod/strict) pragma.

## `nowarnings`

This skips turning on the [warnings](https://metacpan.org/pod/warnings) pragma.

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

## Explicit Features and Bundles by Name

You can always provide a list of explicit features and bundles from [feature](https://metacpan.org/pod/feature).
If provided, these will be enabled regardless of the other import flags set.

    use exact qw( noexperiments fc signatures );

Bundles provided can be exactly like those described in [feature](https://metacpan.org/pod/feature) or in a
variety of obvious forms:

- :5.26
- 5.26
- v5.26
- 26

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

This software is copyright (c) 2018 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
