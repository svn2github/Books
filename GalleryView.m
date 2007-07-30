//
//  GalleryView.m
//  Books
//
//  Created by Chris Karr on 7/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GalleryView.h"
#import "GalleryCoverView.h"

@implementation GalleryView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) 
	{
		page = 0;
		count = 0;
		
		controlVisible = false;
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

	int rowCount = ((int) rect.size.width / (int) size);
	int colCount = ((int) rect.size.height / (int) size);

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
		if (x + size > rect.size.width)
		{
			x = xSpacing;
			y = y - size - ySpacing;
		}

		if (y < 0)
			break;

		[[subs objectAtIndex:i] setFrame:NSMakeRect(x, y, size, size)];
		[[subs objectAtIndex:i] setBook:[selectedBooks objectAtIndex:i]];
		[[subs objectAtIndex:i] setHidden:NO];
	
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

@end
