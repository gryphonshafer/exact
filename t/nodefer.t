use Test2::V0;
use exact -nodefer;

like( dies {defer { 1 } }, qr/Can't locate object method "defer"/, 'nodefer' );

done_testing;
