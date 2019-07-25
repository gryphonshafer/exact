use Test::More tests => 3;
use Test::Exception;

BEGIN {
    package exact::____test {
        use exact;

        sub import {
            my ( $self, $caller, $params ) = @_;
            {
                no strict 'refs';
                *{ $caller . '::thx' } = \&thx;
            }
            exact->autoclean( -except => [ 'thx', 'lives_ok', 'is' ] );
        }

        sub thx {
            return 1138;
        }
    };

    $INC{'exact/____test.pm'} = 1;

    use_ok( 'exact', '____test' );
}

my $thx = 0;
lives_ok( sub { $thx = thx() }, 'thx() imported OK' );
is( $thx, 1138, 'thx() returns correct value' );
