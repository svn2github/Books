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
	
	if (arrow == 13 || arrow == 3)
	{
		NSNotification * notification = [NSNotification notificationWithName:BOOKS_SHOW_INFO object:nil];
		[[NSNotificationCenter defaultCenter] postNotification:notification];
	}
	else if (arrow == NSRightArrowFunctionKey || arrow == NSLeftArrowFunctionKey || arrow == NSUpArrowFunctionKey ||
			 arrow == NSDownArrowFunctionKey || arrow == NSHomeFunctionKey || arrow == NSEndFunctionKey || 
			 arrow == NSPageUpFunctionKey || arrow == NSPageDownFunctionKey || arrow == ' ')
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
			else if (arrow == NSPageUpFunctionKey)
				position -= (rowCount * colCount);
			else if (arrow == NSPageDownFunctionKey || arrow == ' ')
				position += (rowCount * colCount);

			if (position < 0)
				position = 0;
			if (position > [[bookList arrangedObjects] count] - 1)
				position = [[bookList arrangedObjects] count] - 1;
			
			int pos_page = 0;
			if (position != 0)
				pos_page = position / (rowCount * colCount);
			
			if ([pages intValue] != pos_page)
			{
				[pages setIntValue:pos_page];
				[self setNeedsDisplay:YES];
			}
				
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
		page = 0;
		count = 0;
		
		rowCount = 0;
		colCount = 0;
		
		controlVisible = false;
		shouldDrawFocusRing = false;
		lastResp = nil;
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

	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"hideControl") 
		name:GALLERY_HIDE_CONTROL object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"showControl") 
		name:GALLERY_SHOW_CONTROL object:nil];
}

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
	context:(void *)context
{
    if ([keyPath isEqual:@"arrangedObjects"] || [keyPath isEqual:@"Gallery Size"])
	{
		[pages setIntValue:0];
		selectedBooks = [bookList arrangedObjects];
	}

	[self setNeedsDisplay:YES];
}

- (void) drawBoxesInRect:(NSRect) rect
{
	rect = [self frame];
	
	NSNumber * prefSize = [[NSUserDefaults standardUserDefaults] valueForKey:@"Gallery Size"];

	int listSize = [[bookList arrangedObjects] count];
	
	float size = 128;
	
	if (prefSize != nil)
		size = [prefSize floatValue];
	
	if (size > rect.size.height - 20)
		size = rect.size.height - 20;
	
	NSArray * subs = [self subviews];

	rowCount = ((int) rect.size.width / (int) size);
	colCount = ((int) rect.size.height / (int) size);

	count = rowCount * colCount;

	[pages setMinValue:0.0];

	if (count > 0)
	{
		[pages setMaxValue:(double) (listSize / count)];
		[pages setNumberOfTickMarks:(listSize / count) + 1];
	}
	else
	{
		[pages setMaxValue:0.0];
		[pages setNumberOfTickMarks:1];
	}
	
	if (listSize < rowCount)
	{
		rowCount = listSize;
		colCount = 1;
	}
	
	float xSpacing = (rect.size.width - (rowCount * size)) / (float) (rowCount + 1);
	float ySpacing = (rect.size.height - (colCount * size)) / (float) (colCount + 1);
	
	float x = xSpacing;
	float y = rect.size.height - size - ySpacing;

	int i = 0;

	if ([subs count] < [selectedBooks count])
	{
		for (i = [subs count]; i < [selectedBooks count]; i++)
		{
			GalleryCoverView * gcv = [[GalleryCoverView alloc] init];
			[gcv setFrame:NSMakeRect(x, y - size, size, size)];
			[self addSubview:gcv];
		}
	}
	
	for (i = 0; i < [subs count]; i++)
		[[subs objectAtIndex:i] setHidden:YES];
		
	page = [pages intValue];
	
	if (count > 0)
		[text setStringValue:[NSString stringWithFormat:NSLocalizedString (@"Page %d of %d", nil), (page + 1), (([[bookList arrangedObjects] count] / count) + 1), nil]];

	for (i = (page * count); i < ((page + 1) * count) && i < [selectedBooks count]; i++)
	{
		GalleryCoverView * gcv = [subs objectAtIndex:i];
		BookManagedObject * book = [selectedBooks objectAtIndex:i];
		
		if (x + size > rect.size.width)
		{
			x = xSpacing;
			y = y - size - ySpacing;
		}

		if (y < 0)
			break;

		[gcv setFrame:NSMakeRect(x, y, size, size)];
		
		if ([gcv getBook] != book)
			[gcv setBook:book];
			
		[gcv setHidden:NO];
	
		x = x + size + xSpacing;
	}
}

- (void)drawRect:(NSRect)rect 
{
	[icon removeFromSuperview];
	[controlView removeFromSuperview];
		
	[[NSColor colorWithCalibratedRed:0.921875 green:0.921875 blue:0.921875 alpha:1.0] setFill];
//	[[[NSColor controlAlternatingRowBackgroundColors] objectAtIndex:1] setFill];

	NSRectFill(rect);

	[self drawBoxesInRect:rect];

	if (controlVisible)
	{
		[self addSubview:controlView];
		[controlView setFrameOrigin:NSMakePoint (([self frame].size.width - [controlView frame].size.width - 10), 10)];
	}
	else
	{
		[self addSubview:icon];
		[icon setFrameOrigin:NSMakePoint (([self frame].size.width - [icon frame].size.width - 10), 10)];
	}

	if (shouldDrawFocusRing) 
    {
        NSSetFocusRingStyle (NSFocusRingOnly);
        NSRectFill([self bounds]);
		
		shouldDrawFocusRing = NO;
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

- (void) hideControl
{
	controlVisible = false;
	
	[self setNeedsDisplay:YES];
}

- (void) showControl
{
	controlVisible = true;
	
	[self setNeedsDisplay:YES];
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

- (BOOL) needsDisplay;
{
    NSResponder* resp = nil;

    if ([[self window] isKeyWindow]) 
    {
        resp = [[self window] firstResponder];

        if (resp == lastResp) 
            return [super needsDisplay];
    } 
    else if (lastResp == nil)  
    {
        return [super needsDisplay];
    }
	
    shouldDrawFocusRing = (resp != nil && resp == self); 
    lastResp = resp;

    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];

    return YES;
}

@end
