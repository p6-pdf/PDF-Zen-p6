#!/usr/bin/env perl6
use v6;

use PDF::Class;
use PDF::Class::OutlineNode;
use PDF::Destination :DestinationArray;

use PDF::IO::Str;
use PDF::IO::Handle;
use PDF::COS;

my subset IndRef of Pair where {.key eq 'ind-ref'};
sub ind-ref(IndRef $_ ) {
      (.value[0], .value[1], 'R').join: ' ';
}

my %page-index;
my  PDF::Class $pdf;

sub named-dest($_) {
    state $named-dests = do with $pdf.catalog.Names {
        .names with .Dests;
    } // $pdf.catalog.Dests // {};
    $named-dests{$_};
}

sub MAIN(Str $infile,           #= input PDF
	 Str :$password = '',   #= password for the input PDF, if encrypted
         Bool :$title = True,   #= display title (if present)
         Bool :$labels = True   #= don't display page labels
    ) {

    my $input = $infile eq '-'
	?? PDF::IO::Str.new( :value($*IN.slurp-rest( :enc<latin-1> )) )
	!! PDF::IO::Handle.new( :value($infile.IO.open( :enc<latin-1> )) );

    $pdf .= open( $input, :$password );

    my $page-labels = $pdf.catalog.PageLabels
        if $labels;

    my @index = $pdf.catalog.Pages.page-index;
    %page-index = @index.pairs.map: {
        my $page-num = .key + 1;
        $page-num = .page-label($page-num)
            with $page-labels;
        ind-ref(.value) => $page-num;
    }

    my $nesting = 0;

    if $title {
        with $pdf.Info {
            with .Title {
                given .trim {
                    unless $_ eq '' {
                        say $_;
                        $nesting++;
                    }
                }
            }
        }
    }

    with $pdf.catalog.Outlines {
        toc($_, :$nesting) for .get-kids;
    }
    else {
        note "document does not contain outlines: $infile";
    }
}

# assumed a string is a named destination
multi sub show-dest(Str $_) {
    show-dest(named-dest($_));
}

multi sub show-dest(Hash $deref where .<D>.defined) {
    show-dest($deref<D>);
}

multi sub show-dest(IndRef $_) {
    my $ref = ind-ref($_);
    %page-index{$ref}  // $ref;
}

multi sub show-dest(DestinationArray $_) {
    show-dest(.values[0]);
}

multi sub show-dest($_) is default {
    Nil
}


sub toc(PDF::Class::OutlineNode $outline, :$nesting! is copy) {
    my $where = do with $outline.Dest // $outline.A { show-dest($_) };
    with $where {
        say( ('  ' x $nesting) ~ $outline.Title.trim ~ ' . . . ' ~ $_);
        $nesting++;
        toc($_, :$nesting)
            for $outline.get-kids;
    }
}

=begin pod

=head1 SYNOPSIS

pdf-toc.p6 [options] file.pdf

Options:
   --password   password for an encrypted PDF
   --/title     disable printing of title (if present)
   --/labels    display raw page numbers

=head1 DESCRIPTION

Prints a table of contents for a given PDF, using the outlines, names and page-labels contained in the PDF.

Note that not every PDF contains contains a table of contents. C<pdf-info.p6> can be used to check this:

    % pdf-info.p6 my-doc.pdf | grep Outlines:
    Outlines:     yes

If C<Outlines> is C<yes>, the PDF probably has a table of contents.

=end pod
