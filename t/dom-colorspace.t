use v6;
use Test;

plan 12;

use PDF::DOM::Type;
use PDF::Storage::IndObj;
use PDF::Grammar::PDF;
use PDF::Grammar::PDF::Actions;
use PDF::Grammar::Test :is-json-equiv;

my $actions = PDF::Grammar::PDF::Actions.new;

my $input = q:to"--END-OBJ--";
16 0 obj% Alternate color space for DeviceN space
[ /CalRGB
<< /WhitePoint [ 1.0 1.0 1.0 ] >>
]
endobj
--END-OBJ--

PDF::Grammar::PDF.parse($input, :$actions, :rule<ind-obj>)
    // die "parse failed";
my $ast = $/.ast;
my $ind-obj = PDF::Storage::IndObj.new( |%$ast);
is $ind-obj.obj-num, 16, '$.obj-num';
is $ind-obj.gen-num, 0, '$.gen-num';
my $color-space-obj = $ind-obj.object;
isa-ok $color-space-obj, ::('PDF::DOM::Type')::('ColorSpace::CalRGB');
is $color-space-obj.type, 'ColorSpace', '$.type accessor';
is $color-space-obj.subtype, 'CalRGB', '$.subtype accessor';
is-json-equiv $color-space-obj[1], { :WhitePoint[ 1.0, 1.0, 1.0 ] }, 'array access';
is-json-equiv $color-space-obj[1]<WhitePoint>, [ 1.0, 1.0, 1.0 ], 'WhitePoint dereference';
is-json-equiv $color-space-obj.WhitePoint, $color-space-obj[1]<WhitePoint>, '$WhitePoint accessor';
is-deeply $ind-obj.ast, $ast, 'ast regeneration';

require ::('PDF::DOM::Type')::('ColorSpace::CalGray');
my $cal-gray = ::('PDF::DOM::Type')::('ColorSpace::CalGray').new;
isa-ok $cal-gray, ::('PDF::DOM::Type')::('ColorSpace::CalGray'), 'new CS class';
is $cal-gray.subtype, 'CalGray', 'new CS subtype';
isa-ok $cal-gray[1], Hash, 'new CS Dict';
