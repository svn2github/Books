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
			int maxIndex = [[bookList arrangedObjects] count] - 1;
			
			NSIndexSet * selects = [bookList selectionIndexes];
		
			int position = [selects firstIndex];
		
			if (arrow == NSRightArrowFunctionKey)
				position++;
			else if (arrow == NSLeftArrowFunctionKey)
				position--;
			else if (arrow == NSUpArrowFunctionKey)
			{
				if (position - rowCount > 0)
					position -= rowCount;
			}
			else if (arrow == NSDownArrowFunctionKey)
			{
				if (position + rowCount <= maxIndex)
					position += rowCount;
			}
			else if (arrow == NSHomeFunctionKey)
				position = 0;
			else if (arrow == NSEndFunctionKey)
				position = maxIndex;

			if (position < 0)
				position = 0;
			if (position > maxIndex)
				position = maxIndex;
				
			[bookList setSelectionIndex:position];
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
	
	[self setNeedsDisplay:YES];
}

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
	context:(void *)context
{
    if ([keyPath isEqual:@"arrangedObjects"])
	{
		[bookList setSelectionIndexes:[NSIndexSet indexSet]];

		NSArray * subs = [self subviews];
	
		int i = 0;
		for (i = 0; i < [subs count]; i++)
		{
			[[subs objectAtIndex:i] setHidden:YES];
			[[subs objectAtIndex:i] setBook:nil];
		}

	}
	else if ([keyPath isEqual:@"selectedObjects"])
	{
		int select = [bookList selectionIndex];
		
		if (select != NSNotFound)
		{
			NSClipView * clip = (NSClipView *) [self superview];
			NSScrollView * scroll = (NSScrollView *) [clip superview];

			NSView * view = [[self subviews] objectAtIndex:select];

			NSRect frame = [view frame];
			NSRect clipRect = [clip documentVisibleRect];

			NSRect newFrame = [clip convertRect:frame fromView:self];

			NSRect intersect = NSIntersectionRect (frame, clipRect);
			
			if (abs(newFrame.size.height - intersect.size.height) > 1)
			{
				BOOL below = NO;
				
				if (intersect.origin.x == 0 && intersect.origin.y == 0 && newFrame.origin.y < clipRect.origin.y)
					below = YES;
				else if (frame.origin.y < intersect.origin.y)
					below = YES;

				if (below)
					[[scroll documentView] scrollPoint:NSMakePoint (0, frame.origin.y)];
				else 
					[[scroll documentView] scrollPoint:NSMakePoint (0, frame.origin.y + frame.size.height - clipRect.size.height)];
			}
		}
	}

	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect 
{
	NSRect clipRect = rect;
	
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

	float xSpacing = (rect.size.width - (rowCount * size)) / (float) (rowCount + 1);
	float ySpacing = xSpacing; 
	
	float x = xSpacing;

	float y = ((size + ySpacing) * colCount); 

	if (y + ySpacing < [[self superview] frame].size.height)
		y = [[self superview] frame].size.height - ySpacing;

	NSSize newSize = NSMakeSize (rect.size.width, y + ySpacing);

	BOOL sameSize = (newSize.height == [self frame].size.height);
		
	if (!sameSize)
	{
		[self setFrameSize:newSize];
		[self display];
		[self setNeedsDisplay:YES];
		return;
	}
	
	int i = 0;

	if ([subs count] < listSize)
	{
		for (i = [subs count]; i < listSize; i++)
		{
			GalleryCoverView * gcv = [[GalleryCoverView alloc] init];
			[self addSubview:gcv];
		}
	}

	y = y - size;

	subs = [self subviews];
	
	for (i = 0; i < [subs count]; i++)
	 	[[subs objectAtIndex:i] setHidden:YES];

	for (i = 0; i < listSize; i++)
	{
		GalleryCoverView * gcv = [subs objectAtIndex:i];
		BookManagedObject * book = [[bookList arrangedObjects] objectAtIndex:i];
		
		if (x + size > rect.size.width)
		{
			x = xSpacing;
			y = y - size - ySpacing;
		}

		NSRect gcvFrame = NSMakeRect(x, y, size, size);

		[gcv setFrame:gcvFrame];

		// if (abs (NSMidY (gcvFrame) - NSMidY (clipRect)) < clipRect.size.height)
		if (NSIntersectsRect (gcvFrame, clipRect))
		{
			[gcv setBook:book];
			[gcv setHidden:NO];
		}
		else
		{
			if (abs (NSMidY (gcvFrame) - NSMidY (clipRect)) > clipRect.size.height * 1.5)
				[gcv setBook:nil];
			[gcv setHidden:YES];
		}
	
		x = x + size + xSpacing;
	}
	
	if (listSize > 0 && [bookList selectionIndex] == NSNotFound)
	{
		[bookList setSelectionIndex:0];
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
