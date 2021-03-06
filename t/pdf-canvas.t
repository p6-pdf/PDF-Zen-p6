use v6;
use Test;
plan 2;

use PDF::Class;
my PDF::Class $pdf .= new;
my $page = $pdf.add-page;
my $header-font = $page.core-font( :family<Helvetica>, :weight<bold> );

try {require HTML::Canvas::To::PDF;}
if $! {
    skip-rest 'HTML::Canvas::To::PDF required to run canvas tests';
    exit;
}

$page.canvas: {
    .beginPath();
    .arc(95, 50, 40, 0, 2 * pi);
    .stroke();
    .fillText("Hello World", 10, 50);
}

# ensure consistant document ID generation
$pdf.id =  $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok { $pdf.save-as("t/pdf-canvas.pdf", :!info) }, 'save-as';

throws-like { $pdf.unknown-method }, X::Method::NotFound, '$pdf unknown method';

done-testing;
