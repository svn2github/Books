//
//  GalleryCoverView.m
//  Books
//
//  Created by Chris Karr on 7/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GalleryCoverView.h"
#import "GalleryView.h"
#import "BooksAppDelegate.h"

@implementation GalleryCoverView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];

    if (self) 
	{
		margin = 10;

		image = nil;
		currentBook = nil;
			
		imageView = [[NSImageView alloc] init];
		[imageView setImageScaling:NSScaleProportionally];
		[imageView setImageFrameStyle:NSImageFrameNone];
		[self addSubview:imageView];
		[imageView setHidden:NO];

		timer = nil;
		click = false;
		inited = false;
    }
    return self;
}

- (void) drawSelectedBackground:(NSRect)rect
{
	rect = NSMakeRect (0, 0, rect.size.width, rect.size.height); 

	float radius = 10.0;
	radius = MIN(radius, 0.5f * MIN(NSWidth(rect), NSHeight(rect)));
	
	[[NSColor alternateSelectedControlColor] setFill];

	NSBezierPath * path = [NSBezierPath bezierPath];
	
	rect = NSInsetRect(rect, radius, radius);
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0 endAngle: 90.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0 endAngle:180.0];
	[path closePath];
	
	[path fill];
}

- (void) updateView
{
	if (inited)
		return;

	if (currentBook == nil)
	{
		[self setToolTip:nil];
		
		if (image != nil && image != [NSImage imageNamed:@"Books"])
			[image release];

		image = nil;
	}
	else
	{
		NSData * data = [currentBook getCoverImage];
		if (data != nil)
		{
			if (image != nil && image != [NSImage imageNamed:@"Books"])
				[image release];

			image = [[NSImage alloc] initWithData:data];
		}
		else
			image = [NSImage imageNamed:@"Books"];

		[self setToolTip:[currentBook valueForKey:@"title"]];
	}
	
	[imageView setImage:image]; 
	
	inited = true;
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
	rect = [self frame];

	[self updateView];
	
	[imageView setFrame:NSMakeRect (margin, margin, (rect.size.width - margin - margin), 
		(rect.size.height - margin - margin))];

	if ([[((GalleryView *) [self superview]) selectedBooks] containsObject:currentBook])
		[self drawSelectedBackground:rect];
}

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
	context:(void *)context
{
	inited = false;
	[self updateView];
}

- (BookManagedObject *) getBook
{
	return currentBook;
}

- (void) setBook:(BookManagedObject *) book
{
	if (currentBook != nil)
	{
		[currentBook removeObserver:self forKeyPath:@"coverImage"];
		[currentBook removeObserver:self forKeyPath:@"title"];
	}

	currentBook = book;

	[currentBook addObserver:self forKeyPath:@"coverImage" options:NSKeyValueObservingOptionNew context:NULL];
	[currentBook addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];

	inited = false;
}

- (NSView *)hitTest:(NSPoint)aPoint
{
	NSPoint p = [[self superview] convertPoint:aPoint toView:self];
	
	NSSize myFrame = [self frame].size;
	
	if (p.x >= 0 && myFrame.width >= p.x && p.y >= 0 && myFrame.height >= p.y && ![self isHidden])
		return self;
	
	return [super hitTest:aPoint];
}

- (void) resetClick:(NSTimer*) theTimer
{
	click = false;

	[timer invalidate];
	[timer release];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[((GalleryView *) [self superview]) setSelectedBook:currentBook];

	if (click)
	{
		NSNotification * notification = [NSNotification notificationWithName:BOOKS_SHOW_INFO object:nil];
		[[NSNotificationCenter defaultCenter] postNotification:notification];

		[self resetClick:timer];
		click = false;
	}
	else
	{
		timer = [[NSTimer scheduledTimerWithTimeInterval:(GetDblTime() / 60.0) target:self 
					selector:NSSelectorFromString(@"resetClick:") userInfo:nil repeats:NO] retain];
		
		click = true;
	}
	
	[super mouseUp:theEvent];
}

@end
