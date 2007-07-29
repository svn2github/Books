//
//  GalleryCoverView.m
//  Books
//
//  Created by Chris Karr on 7/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GalleryCoverView.h"
#import "GalleryView.h"

@implementation GalleryCoverView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) 
	{
		margin = 10;

		image = nil;
			
		imageView = [[NSImageView alloc] init];
		[imageView setImageScaling:NSScaleProportionally];
		[imageView setImageFrameStyle:NSImageFrameNone];
		[self addSubview:imageView];
		[imageView setHidden:NO];

		tag = -1;
		hover = false;
    }
    return self;
}

- (void) drawHoverBackground:(NSRect)rect
{
	float radius = 10.0;
	radius = MIN(radius, 0.5f * MIN(NSWidth(rect), NSHeight(rect)));
	
	// [[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:0.1 alpha:0.8] setFill];
	[[NSColor alternateSelectedControlColor] setFill];

	NSBezierPath* path = [NSBezierPath bezierPath];
	
	rect = NSInsetRect(rect, radius, radius);
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0 endAngle: 90.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0 endAngle:180.0];
	[path closePath];
	
	[path fill];
}

- (void)drawRect:(NSRect)rect
{
	if ([[((GalleryView *) [self superview]) selectedBooks] containsObject:currentBook])
		[self drawHoverBackground:rect];
		
	[imageView setFrame:NSMakeRect (margin, margin, (rect.size.width - margin - margin), 
		(rect.size.height - margin - margin))];
}

- (void) setBook:(BookManagedObject *) book
{
	if (book != nil && currentBook != book)
	{
		[self setToolTip:[book valueForKey:@"title"]];
	
		if (image != nil && image != [NSImage imageNamed:@"Books"])
			[image release];
		
		NSData * data = [book getCoverImage];
		if (data != nil)
			image = [[NSImage alloc] initWithData:data];
		else
			image = [NSImage imageNamed:@"Books"];
			
		[imageView setImage:image]; 
		
	}
	else if (book == nil)
	{
		[self setToolTip:nil];
		
		if (image != nil && image != [NSImage imageNamed:@"Books"])
			[image release];

		image = nil;
	}

	currentBook = book;

	[self setNeedsDisplay:YES];
}

- (NSView *)hitTest:(NSPoint)aPoint
{
	NSPoint p = [[self superview] convertPoint:aPoint toView:self];
	
	NSSize myFrame = [self frame].size;
	
	if (p.x >= 0 && myFrame.width >= p.x && p.y >= 0 && myFrame.height >= p.y && ![self isHidden])
		return self;
	
	return [super hitTest:aPoint];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[((GalleryView *) [self superview]) setSelectedBook:currentBook];
}

@end
