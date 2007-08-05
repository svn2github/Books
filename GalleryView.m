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

- (void) updateGallerySize
{
	NSNumber * prefSize = [[NSUserDefaults standardUserDefaults] valueForKey:@"Gallery Size"];

	gallerySize = 128;
	
	if (prefSize != nil)
		gallerySize = [prefSize floatValue];
}

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
			int maxIndex = [arrangedBooks count] - 1;
			
			int position = [bookList selectionIndex];
		
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
				
			[self setSelectedView:[[self subviews] objectAtIndex:position]];
		}
	}
	else
		[super keyDown:event];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) 
	{
		arrangedBooks = [[NSArray alloc] init];
		gallerySize = 128;
    }
    return self;
}

- (void) awakeFromNib
{
	[bookList addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionNew context:NULL];
	[bookList addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:NULL];
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"Gallery Size" options:NSKeyValueObservingOptionNew context:NULL];
	
	[self updateGallerySize];
	[self setNeedsDisplay:YES];
}

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
	context:(void *)context
{
	NSArray * subs = [self subviews];

    if ([keyPath isEqual:@"arrangedObjects"])
	{
		if (!([arrangedBooks isEqualToArray:[bookList arrangedObjects]]))
		{
			NSLog (@"");
			
			[bookList setSelectionIndexes:[NSIndexSet indexSet]];
	
			int i = 0;
			for (i = 0; i < [subs count]; i++)
			{
				GalleryCoverView * sub = [subs objectAtIndex:i];
				[sub setHidden:YES];
				[sub setBook:nil];
			}
		
			if (arrangedBooks != nil)
				[arrangedBooks release];
				
			arrangedBooks = [[[bookList arrangedObjects] copy] retain];

			int listSize = [arrangedBooks count];
			
			subs = [self subviews];
			
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
			{
				GalleryCoverView * gcv = [subs objectAtIndex:i];
				[gcv setHidden:YES];
				[gcv setBook:nil];
			}
			
			if (listSize > 0)
				[self setSelectedView:[[self subviews] objectAtIndex:0]];
		}
	}
	else if ([keyPath isEqual:@"selectedObjects"])
	{
		int select = [bookList selectionIndex];
		
		if (select != NSNotFound && [subs count] > 0)
		{
			NSClipView * clip = (NSClipView *) [self superview];
			NSScrollView * scroll = (NSScrollView *) [clip superview];

			NSView * view = [subs objectAtIndex:select];

			if (![self isSelectedView:view])
				[self setSelectedView:view];
				
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
	else if ([keyPath isEqual:@"Gallery Size"])
	{
		[self updateGallerySize];
	}

	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect 
{
	NSRect clipRect = rect;
	
	rect = [self frame];
	
	int listSize = [arrangedBooks count];
	
	if (gallerySize > [[[self superview] superview] frame].size.height)
		gallerySize = [[[self superview] superview] frame].size.height * 0.95;
	
	NSArray * subs = [self subviews];

	rowCount = ((int) rect.size.width / (int) gallerySize);
	
	colCount = (listSize / rowCount);
	
	if (listSize % rowCount != 0)
		colCount += 1;

	float xSpacing = (rect.size.width - (rowCount * gallerySize)) / (float) (rowCount + 1);
	float ySpacing = xSpacing; 
	
	float x = xSpacing;

	float y = ((gallerySize + ySpacing) * colCount); 

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
	
	y = y - gallerySize;

	int i = 0;
	for (i = 0; i < [subs count]; i++)
	{
		GalleryCoverView * gcv = [subs objectAtIndex:i];
		
		if (x + gallerySize > rect.size.width)
		{
			x = xSpacing;
			y = y - gallerySize - ySpacing;
		}

		NSRect gcvFrame = NSMakeRect(x, y, gallerySize, gallerySize);
		[gcv setFrame:gcvFrame];

		if ([self isSelectedView:gcv] && !NSIntersectsRect (gcvFrame, clipRect))
			[self observeValueForKeyPath:@"selectedObjects" ofObject:bookList change:nil context:nil];
		
		if (abs (NSMidY (gcvFrame) - NSMidY (clipRect)) < clipRect.size.height * 1.5 && i < [arrangedBooks count])
		{
			BookManagedObject * book = [arrangedBooks objectAtIndex:i];
			
			[gcv setBook:book];
			[gcv setHidden:NO];
		}
		else if (abs (NSMidY (gcvFrame) - NSMidY (clipRect)) > clipRect.size.height * 2.5)
		{
			[gcv setBook:nil];
			[gcv setHidden:YES];
		}
		else
			[gcv setHidden:YES];
			
		if ([[bookList selectionIndexes] count] == 0)
			[self setSelectedView:gcv];
	
		x = x + gallerySize + xSpacing;
	}
}

- (void) setSelectedView:(NSView *) v
{
	int index = [[self subviews] indexOfObject:v];

	// NSMutableIndexSet * selects = [NSMutableIndexSet indexSet];
	// [selects addIndexes:[bookList selectionIndexes]];

	// [selects addIndex:index];
	
	[bookList setSelectionIndex:index];
}

- (BOOL) isSelectedView:(NSView *) v;
{
	unsigned int index = [[self subviews] indexOfObject:v];
	
	return ([[bookList selectionIndexes] containsIndex:index]);
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
