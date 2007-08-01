//
//  GalleryView.m
//  Books
//
//  Created by Chris Karr on 7/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GalleryView.h"
#import "GalleryCoverView.h"
#import "BooksAppDelegate.h"

@implementation GalleryView

- (void) keyDown: (NSEvent *) event
{
	unichar arrow = [[event characters] characterAtIndex:0];
	
	if (arrow == ' ')
		arrow = NSDownArrowFunctionKey;
		
	if (arrow == 13 || arrow == 3)
	{
		NSNotification * notification = [NSNotification notificationWithName:BOOKS_SHOW_INFO object:nil];
		[[NSNotificationCenter defaultCenter] postNotification:notification];
	}
	else if (arrow == NSRightArrowFunctionKey || arrow == NSLeftArrowFunctionKey || arrow == NSUpArrowFunctionKey ||
			 arrow == NSDownArrowFunctionKey || arrow == NSHomeFunctionKey || arrow == NSEndFunctionKey)
	{
		if ([[bookList selectedObjects] count] == 0)
			[bookList selectNext:self];
		else
		{
			NSIndexSet * selects = [bookList selectionIndexes];
		
			int position = [selects firstIndex];
		
			if (arrow == NSRightArrowFunctionKey)
				position++;
			else if (arrow == NSLeftArrowFunctionKey)
				position--;
			else if (arrow == NSUpArrowFunctionKey)
				position -= rowCount;
			else if (arrow == NSDownArrowFunctionKey)
				position += rowCount;
			else if (arrow == NSHomeFunctionKey)
				position = 0;
			else if (arrow == NSEndFunctionKey)
				position = [[bookList arrangedObjects] count] - 1;

			if (position < 0)
				position = 0;
			if (position > [[bookList arrangedObjects] count] - 1)
				position = [[bookList arrangedObjects] count] - 1;
			
			int pos_page = 0;
			if (position != 0)
				pos_page = position / (rowCount * colCount);
				
			[bookList setSelectionIndex:position];
			
			NSClipView * clip = (NSClipView *) [self superview];
			NSScrollView * scroll = (NSScrollView *) [clip superview];
	
			NSRect clipRect = [clip documentVisibleRect];
	
			NSView * view = [[self subviews] objectAtIndex:position];
			NSRect frame = [view frame];
	
			float y = (frame.origin.y + (frame.size.height / 2)) - (clipRect.size.height / 2);

			[[scroll documentView] scrollPoint:NSMakePoint (0, y)];
		}
	}
	else
		[super keyDown:event];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) 
	{

    }
    return self;
}

- (void) awakeFromNib
{
	[bookList addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionNew context:NULL];
	[bookList addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:NULL];
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"Gallery Size" options:NSKeyValueObservingOptionNew context:NULL];

	[[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1.0] setFill];
	NSRectFill([self frame]);
}

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
	context:(void *)context
{
    if ([keyPath isEqual:@"arrangedObjects"] || [keyPath isEqual:@"Gallery Size"])
		selectedBooks = [bookList arrangedObjects];

	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect 
{
	NSRect oldRect = rect;
	
	rect = [self frame];
	
	NSNumber * prefSize = [[NSUserDefaults standardUserDefaults] valueForKey:@"Gallery Size"];

	int listSize = [[bookList arrangedObjects] count];
	
	float size = 128;
	
	if (prefSize != nil)
	 	size = [prefSize floatValue];
		
	if (size > [[[self superview] superview] frame].size.height)
		size = [[[self superview] superview] frame].size.height * 0.95;
	
	NSArray * subs = [self subviews];

	rowCount = ((int) rect.size.width / (int) size);
	
	colCount = (listSize / rowCount);
	
	if (listSize % rowCount != 0)
		colCount += 1;

	if (listSize < rowCount)
	{
		rowCount = listSize;
		colCount = 1;
	}
	
	float xSpacing = (rect.size.width - (rowCount * size)) / (float) (rowCount + 1);
	float ySpacing = xSpacing; 
	
	if (colCount == 1)
		ySpacing = (oldRect.size.height - size) / 2;
	
	float x = xSpacing;

	float y = ((size + ySpacing) * colCount); 
	
	int i = 0;

	NSSize newSize = NSMakeSize (rect.size.width, y + ySpacing);
	
	y = y - size;
	
	[self setFrameSize:newSize];
	
	if ([subs count] < listSize)
	{
		for (i = [subs count]; i < listSize; i++)
		{
			GalleryCoverView * gcv = [[GalleryCoverView alloc] init];
			[self addSubview:gcv];
		}
	}

	subs = [self subviews];
	
	for (i = 0; i < [subs count]; i++)
	 	[[subs objectAtIndex:i] setHidden:YES];

	for (i = 0; i < listSize; i++)
	{
		GalleryCoverView * gcv = [subs objectAtIndex:i];
		BookManagedObject * book = [selectedBooks objectAtIndex:i];
		
		if (x + size > rect.size.width)
		{
			x = xSpacing;
			y = y - size - ySpacing;
		}

		[gcv setFrame:NSMakeRect(x, y, size, size)];
		
		if ([gcv getBook] != book)
			[gcv setBook:book];
			
		[gcv setHidden:NO];
	
		x = x + size + xSpacing;
	}
}

- (void) setFrameSize:(NSSize) size
{
	[super setFrameSize:size];
	
	if ([[bookList selectedObjects] count] == 0)
	{
		NSClipView * clip = (NSClipView *) [self superview];
		NSScrollView * scroll = (NSScrollView *) [clip superview];
	
		[[scroll documentView] scrollPoint:NSMakePoint (0, size.height)];
		
		[self setNeedsDisplay:YES];
	}
}

- (void) setSelectedBook:(BookManagedObject *) b
{
	[bookList setSelectedObjects:[NSArray arrayWithObject:b]];
}

- (NSArray *) selectedBooks
{
	return [bookList selectedObjects];
}


- (void)mouseUp:(NSEvent *)theEvent
{
	[[self window] makeFirstResponder:self];
	[super mouseUp:theEvent];
}

- (BOOL)acceptsFirstResponder 
{
    return YES;
}

@end
