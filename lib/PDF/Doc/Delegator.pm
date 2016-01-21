use v6;

use PDF::DAO;
use PDF::DAO::Name;
use PDF::DAO::Delegator;

class PDF::Doc::Delegator {...}
PDF::DAO.delegator = PDF::Doc::Delegator;

class PDF::Doc::Delegator
    is PDF::DAO::Delegator {

    use PDF::DAO::Util :from-ast;

    method class-paths {<PDF::Doc::Type PDF::DAO::Type>}

    multi method find-delegate( Str $subclass! where { self.handler{$_}:exists } ) {
        self.handler{$subclass}
    }

    multi method find-delegate( Str $subclass! where 'XRef' | 'ObjStm') {
	require ::('PDF::DAO::Type')::($subclass);
	self.install-delegate( $subclass, ::('PDF::DAO::Type')::($subclass) );
    }

    multi method find-delegate( Str $subclass!, :$fallback!) is default {

        my $handler-class = $fallback;
        my Bool $resolved;

	for self.class-paths -> $class-path {
            require ::($class-path)::($subclass);
            $handler-class = ::($class-path)::($subclass);
            $resolved = True;
            last;
            CATCH {
                when X::CompUnit::UnsatisfiedDependency { }
            }
	}
		
	note "No Doc handler class [{self.class-paths}]::{$subclass}"
	    unless $resolved;

        self.install-delegate( $subclass, $handler-class );
    }

    multi method delegate(Hash :$dict! where {.<FunctionType>:exists}) {
	require ::('PDF::Doc::Type::Function');
	::('PDF::Doc::Type::Function').delegate-function( :$dict );
    }

    multi method delegate(Hash :$dict! where {.<PatternType>:exists}) {
	require ::('PDF::Doc::Type::Pattern');
	::('PDF::Doc::Type::Pattern').delegate-pattern( :$dict );
    }

    multi method delegate(Hash :$dict! where {.<ShadingType>:exists}) {
	require ::('PDF::Doc::Type::Shading');
	::('PDF::Doc::Type::Shading').delegate-shading( :$dict );
    }

    multi method delegate(Hash :$dict! where {(.<Registry>:exists) && (.<Ordering>:exists)}) {
	require ::('PDF::Doc::Type::CIDSystemInfo');
	::('PDF::Doc::Type::CIDSystemInfo');
    }

    multi method delegate( Hash :$dict! where {.<Type>:exists}, :$fallback) {
        my $subclass = from-ast($dict<Type>);
        unless $subclass eq 'Border' {
	    my $subtype = from-ast($dict<Subtype> // $dict<S>);
	    $subclass ~= '::' ~ $subtype if $subtype.defined;
	}
        my $delegate = $.find-delegate( $subclass, :$fallback );
        $delegate;
    }

    #| Reverse lookup for classes when /Subtype is required but /Type is optional
    multi method delegate(Hash :$dict where {.<Subtype>:exists }, :$fallback) {
	my $subtype = from-ast $dict<Subtype>;

	my $type = do given $subtype {
	    when 'Circle' | 'Link' | 'Square' | 'Text' | 'Widget' {
		# todo other Annot sub-types, NYI
		'Annot'
	    }
	    when 'PS' | 'Image' | 'Form'  { 'XObject' }
	    default { Nil }
	};

	if $type {
	    my $class = "PDF::Doc::Type::{$type}::{$subtype}";
	    require ::($class);
	    ::($class);
	}
	else {
	    note "unhandled subtype: PDF::Doc::Type::*::{$subtype}";
	    $fallback;
	}
    }

    #| PDF Spec 1.7 Section 4.5.4 CIE-Based Color Spaces
    subset ColorSpace-Array-CIE where {
	.elems == 2 && do {
	    my $t = from-ast .[0];
	    if $t ~~  PDF::DAO::Name {
		my $d = from-ast .[1];
		$d ~~ Hash && do given $t {
		    when 'CalGray'|'CalRGB'|'Lab' { $d<WhitePoint>:exists}
		    when 'ICCBased'               { $d<N>:exists }
		    default {False}
		}
	    }
	}
    }

    #| PDF Spec 1.7 Section 4.5.5 Special Color Spaces
    subset ColorSpace-Array-Special where {
	my $a = $_;
	3 <= $a.elems <= 5 && do {
	    my $t = from-ast $a[0];
	    $t ~~  PDF::DAO::Name && do given $t {
		when 'Indexed'    { my $hival = from-ast($a[2]); $hival ~~ UInt }
		when 'Separation' { from-ast($a[1]) ~~ PDF::DAO::Name }
		when 'DeviceN'    { from-ast($a[1]) ~~ Array }
		default {False}
	    }
	}
    }

    subset ColorSpace-Array of Array where ColorSpace-Array-CIE | ColorSpace-Array-Special;

    multi method delegate(ColorSpace-Array :$array!) {
	my $colorspace = from-ast $array[0];
	require ::('PDF::Doc::Type::ColorSpace')::($colorspace);
	::('PDF::Doc::Type::ColorSpace')::($colorspace);
    }

    multi method delegate(:$fallback!) is default {
	$fallback;
    }

}