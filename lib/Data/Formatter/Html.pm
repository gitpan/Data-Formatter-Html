package Data::Formatter::Html;
use strict;
use warnings;

our $VERSION = 0.01;
use base qw(Data::Formatter);

######################################
# Constructor                        #
######################################
sub new
{
    my ($class, $outputHandle, %options) = @_;
    
    # Maintain a list of handles to output to
    my $self = bless {__OUTPUT_HANDLE => $outputHandle,
                      __CONTENT_ONLY  => $options{CONTENT_ONLY}}, $class;
    
    if (!$options{CONTENT_ONLY})
    {
        # Append the HTML preamble
        $self->_write(
            '<head>
            <title>Test log</title>
            <style type="text/css">
            <!--
               em   {font-weight: bold; color: red; 
                    font-size: x-large;}
               dt { font-weight: bold;} 
            -->
            </style>
            </head>
            <body>');
    }
    
    return $self;
}

######################################
# Destructor                         #
######################################
sub DESTROY
{
    my ($self) = @_;
    
    if (!$self->{__CONTENT_ONLY})
    {
        # Append the HTML ending tags
        $self->_write('</body></html>');
    }
}

######################################
# Public Methods                     #
######################################

sub heading
{
    my ($self, $text) = @_;
    return ("<h1>$text</h1>");
}

sub emphasized
{
    my ($self, $text) = @_;
    return ("<em>$text</em>");
}

######################################
# Protected methods                  #
######################################
sub _write
{
    my ($self, $text) = @_;
    my $handle = $self->{__OUTPUT_HANDLE} or return;
        
    print $handle ($text);
}

sub _paragraph
{
   my ($self, $arg, %options) = @_;
   return map { ('<p>', $self->_format($_),'</p>') } (@{$arg});
}

sub _text
{
    my ($self, $text) = @_;
    return ($text);
}

sub _table
{
    my ($self, $rows, %options) = @_;
    my $border = defined $options{'tableBorder'} ? $options{'tableBorder'} : 1;
    my $spacing = $options{'tableSpacing'} || 1;
    my $width   = $options{'tableWidth'} || '';
    my $expandRightCol = $options{'tableExpandRightCol'};
    
    my @buffer = ('<table border="' . $border
                . '" cellspacing="' . $spacing
                . '" width="' . $width
                . '">');
    
    foreach my $row (@{$rows})
    {
        push(@buffer, '<tr>');
        
        foreach my $cellIdx (0 .. $#{$row})
        {
            my $cell = $row->[$cellIdx];
            
            # A referenced scalar in a table's cell indicates a header cell
            my $cellType;
            if (ref($cell) && ref($cell) =~ /SCALAR/)
            {
                $cellType =  'th';
                
                my $temp = ${$cell};
                $cell = $temp;
            }
            else
            {
                $cellType =  'td';
            }
            
            if ($cellIdx == $#{$row} && $expandRightCol)
            {
                push(@buffer, "<$cellType" . ' valign="top" width="100%">');
            }
            else
            {
                push(@buffer, "<$cellType" . ' valign="top">');
            }
            
            push(@buffer, $self->_format($cell, %options), "</$cellType>");
        }
        
        push(@buffer, '</tr>');
    }
    push(@buffer, '</table>');
    
    return @buffer;
}

sub _list
{
    my ($self, $list, %options) = @_;
        
    my @buffer;
    foreach my $element (@{$list})
    {
        # Nested lists are not contained in an item as other nested elements are.
        # If they were, it would look weird.
        if ($self->_getStructType($element) =~ /\w+_LIST/)
        {
            push(@buffer, $self->_format($element, %options));
        }
        else
        {
            push(@buffer,
                 '<li>',
                 $self->_format($element, %options),
                 '</li>');
        }
    }
    return @buffer;
}

sub _unorderedList
{
    my ($self, $list, %options) = @_;
    
    return ('<ul>', $self->_list($list, %options), '</ul>');
}

sub _orderedList
{
    my ($self, $list, %options) = @_;
    
    return ('<ol>', $self->_list($list, %options), '</ol>');
}

sub _definitionList
{
    my ($self, $pairs, %options) = @_;
    
    # Output the pairs in alphabetical order with respect to the key
    my @keys = sort (keys %{$pairs});
    
    # Each item maps to a <dt> term element followed by a <dd> definition element
    my @items = map
    {
        ("<dt>$_</dt>",
         '<dd>', $self->_format($pairs->{$_}, %options), '</dd>');
    } @keys;
    
    return ('<dl>', @items, '</dl>');
}


1;

=head1 NAME

Data::Formatter::Html - stringified perl data structures, nicely formatted for users

=head1 SYNOPSIS

  use Data::Formatter::Html;

  my $text = new Data::Formatter::Html(\*STDOUT);
  $text->out('The following foods are tasty:',
             ['Pizza', 'Pumpkin pie', 'Sweet-n-sour Pork']);

   # Outputs,
   #
   # The following foods are tasty:
   #  <ul>
   #  <li> Pizza
   #  <li> Pumpkin pie
   #  <li> Sweet-n-sour Pork
   #  </ul>
   #

  $text->out('Do these things to eat an orange:'
             \['Peal it', 'Split it', 'Eat it']);

   # Outputs,
   #
   # Do these things to eat an orange: 
   # <ol>
   #  <li> Peal it 
   #  <li> Split it 
   #  <li> Eat it 
   # </ol>
   #

   # If you don't need to output to a file, you can also use the format() class method
   # instead of the out() instance method.
   my $nums = Data::Formatter::Html->format(
       'Phone numbers
        { 
            Pat => '123-4567',
            Joe => '999-9999',
            Xenu => '000-0000',
        }); 
          
   # Stores in $nums:
   #
   # Phone numbers 
   # <dl>
   # <dt>Joe</dt><dd>999-9999</dd>
   # <dt>Pat</dt><dd>123-4567</dd>
   # <dt>Xenu</dt><dd>000-0000</dd>
   # </dl>
   #

=head1 DESCRIPTION

A module that converts Perl data structures into HTML code, 
formatting the data nicely for presentation to a human. For 
instance, refs to arrays are converted into bulleted lists, 
refs to arrays that contain only refs to arrays are converted 
into tables, and refs to hashes are converted to definition 
lists.

All in all, data structures are mapped to display elements as follows:

 SCALAR                    => Text,
 REF to an ARRAY of ARRAYs => Table
 REF to an ARRAY           => Unordered (bulleted) list
 Ref to a REF to an ARRAY  => Ordered (numbered) list
 Ref to a HASH             => Definition list

Elements can be nested, so, for instance, you may have an array that 
contains one or more references to arrays, and it will be translated 
into a nested bulletted list.

=head2 Methods

=over 4

=item I<PACKAGE>->new()

Returns a newly created C<Data::Formatter::Html> object.

=item I<PACKAGE>->format(I<ARRAY>)

Returns the string representation of the arguments, formatted nicely.

=item I<$OBJ>->out(I<ARRAY>)

Outputs the string representation of the arguments to the file stream specified in the constructor.

=item I<$OBJ>->heading(I<SCALAR>)

Returns a new data-structure containing the same data as I<SCALAR>, but which will be displayed as a heading if passed to out().
Headings are center aligned, made all uppercase, and surrounded by a thick border.

For example,

	$text->out($text->heading("Test Results"), "All is well!");
 
=item I<$OBJ>->emphasized(I<SCALAR>)

Returns a new data-structure containing the same data as I<SCALAR>, but which will be displayed as emphasized text if passed to out().
Emphasized text is made all uppercase and surrounded by a thin border.

For example,
	
    $text->out($text->emphasized("Cannot find file!"));

=back

=head2 Example

    $formatter->out('Recipes',
        {
            "Zack's Kickin' Bannana Milkshake" =>
            [
                ['Ingredient', 'Amount', 'Preparation'],
                ['1% milk', '1 L',    ''],
                ['Ripe Banana', '2 peeled', \['Peel bananas', 'Chop into quarters for blender']],
                ['Organic eggs', '1 whole', \['Crack', 'Pour']],
                ['Wheat germ', '1 tablespoon', ''],
                ['Honey', 'To taste', 'Mix it in well!'],
            ],
            "Peanutbutter and Jam Sandwich" =>
            [
                ['Ingredient', 'Amount', 'Preparation'],
                ['Bread', '2 slices', ''],
                ['Jam', 'Enough to cover inner face of slice 1', ''],
                ['Peanutbutter', 'Enough to cover inner face of slice 2', '']
            ]
        }
    );

The code above will output the HTML:

=begin html

Recipes
<dl>
<dt>Peanutbutter and Jam Sandwich</dt>
<dd>
<table border="1" cellspacing="1" width="">
<tr>
<td valign="top">
Ingredient
</td>
<td valign="top">
Amount
</td>
<td valign="top">
Preparation
</td>
</tr>
<tr>
<td valign="top">
Bread
</td>
<td valign="top">
2 slices
</td>
</tr>
<tr>
<td valign="top">
Jam
</td>
<td valign="top">
Enough to cover inner face of slice 1
</td>
</tr>
<tr>
<td valign="top">
Peanutbutter
</td>
<td valign="top">
Enough to cover inner face of slice 2
</td>
</tr>
</table>
</dd>
<dt>Zack's Kickin' Bannana Milkshake</dt>
<dd>
<table border="1" cellspacing="1" width="">
<tr>
<td valign="top">
Ingredient
</td>
<td valign="top">
Amount
</td>
<td valign="top">
Preparation
</td>
</tr>
<tr>
<td valign="top">
1% milk
</td>
<td valign="top">
1 L
</td>
<td valign="top">

</td>
</tr>
<tr>
<td valign="top">
Ripe Banana
</td>
<td valign="top">
2 peeled
</td>
<td valign="top">
<ol>
<li>
Peel bananas
</li>
<li>
Chop into quarters for blender
</li>
</ol>
</td>
</tr>
<tr>
<td valign="top">
Organic eggs
</td>
<td valign="top">
1 whole
</td>
<td valign="top">
<ol>
<li>
Crack
</li>
<li>
Pour
</li>
</ol>
</td>
</tr>
<tr>
<td valign="top">
Wheat germ
</td>
<td valign="top">
1 tablespoon
</td>
<td valign="top">

</td>
</tr>
<tr>
<td valign="top">
Honey
</td>
<td valign="top">
To taste
</td>
<td valign="top">
Mix it in well!
</td>
</tr>
</table>
</dd>
</dl>

=end html

Note that the order of elements in a hash is not necessarily the same as the order the elements are printed in; instead, hash elements are sorted alphabetically by their keys before being output.


=head1 SEE ALSO

Data::Formatter::Text - A compatible module that outputs formatted information using ASCII text, rather than HTML.

=head1 AUTHOR

Zachary Blair, E<lt>zack_blair@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Zachary Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
