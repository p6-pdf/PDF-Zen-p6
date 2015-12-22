use v6;

use PDF::DAO::Tie::Hash;

# /Type /Outlines - the Outlines dictionary

role PDF::DOM::Type::OutlineItem
    does PDF::DAO::Tie::Hash {

    use PDF::DAO::Tie;

    has Str $.Title is entry(:required);              #| (Required) The text to be displayed on the screen for this item.
    has Hash $.Parent is entry(:required, :indirect); #| (Required; must be an indirect reference) The parent of this item in the outline hierarchy. The parent of a top-level item is the outline dictionary itself.
    has PDF::DOM::Type::OutlineItem $.Prev is entry(:indirect);       #| (Required for all but the first item at each level; must be an indirect reference)The previous item at this outline level.
    has PDF::DOM::Type::OutlineItem $.Next is entry(:indirect);       #| (Required for all but the last item at each level; must be an indirect reference)The next item at this outline level.
    has PDF::DOM::Type::OutlineItem $.First is entry(:indirect);      #| (Required if the item has any descendants; must be an indirect reference) The first of this item’s immediate children in the outline hierarchy.
    has PDF::DOM::Type::OutlineItem $.Last is entry(:indirect);       #| (Required if the item has any descendants; must be an indirect reference) The last of this item’s immediate children in the outline hierarchy.
    has UInt $.Count is entry;                        #| (Required if the item has any descendants) If the item is open, the total number of its open descendants at all lower levels of the outline hierarchy. If the item is closed, a negative integer whose absolute value specifies how many descendants would appear if the item were reopened.
    has $.Dest is entry;                              #| (Optional; not permitted if an A entry is present) The destination to be displayed when this item is activated
    has Hash $.A is entry;                            #| (Optional; PDF 1.1; not permitted if a Dest entry is present) The action to be performed when this item is activate
    has Hash $.SE is entry(:indirect);                #| (Optional; PDF 1.3; must be an indirect reference) The structure element to which the item refers (see Section 10.6.1, “Structure Hierarchy”).
    #| Note: The ability to associate an outline item with a structure element (such as the beginning of a chapter) is a PDF 1.3 feature. For backward compatibility with earlier PDF versions, such an item should also specify a destination (Dest) corresponding to an area of a page where the contents of the designated structure element are displayed.
    has Numeric @.C is entry(:len(3));                #| (Optional; PDF 1.4) An array of three numbers in the range 0.0 to 1.0, representing the components in the DeviceRGB color space of the color to be used for the outline entry’s text. Default value: [ 0.0 0.0 0.0 ].
    has UInt $.F is entry;                            #| (Optional; PDF 1.4) A set of flags specifying style characteristics for displaying the outline item’s text (see Table 8.5). Default value: 0.

}