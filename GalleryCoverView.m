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

		imageView = [[NSImageView alloc] init];
		[imageView setImageScaling:NSScaleProportionally];
		[imageView setImageFrameStyle:NSImageFrameNone];
		[self addSubview:imageView];
		[imageView setHidden:NO];

		image = nil;
		
		timer = nil;
		click = false;
		inited = false;
    }
    return self;
}

- (NSRect) getBorder:(float) borderWidth
{
	NSImage * img = [imageView image];
	NSSize imageSize = [img size];
	NSSize viewSize = [imageView frame].size;
	
	NSSize borderSize = imageSize;
	
	if (imageSize.width > viewSize.width || imageSize.height > viewSize.height)
	{
		float ratio = imageSize.height / imageSize.width;
		
		if (ratio < 1)
		{
			ratio = viewSize.width / imageSize.width;
			borderSize.width = viewSize.width;
			borderSize.height = imageSize.height * ratio;
		}
		else
		{
			ratio = viewSize.height / imageSize.height;
			borderSize.width = imageSize.width * ratio;
			borderSize.height = viewSize.height;
		}
	}

	
	viewSize = [self frame].size;

	borderSize.width += borderWidth;
	borderSize.height += borderWidth;
	
	float x = (viewSize.width - borderSize.width) / 2;
	float y = (viewSize.height - borderSize.height) / 2;

	NSRect rect = NSMakeRect (x, y, borderSize.width, borderSize.height); 

	return rect;
}

- (void) drawSelectedBackground
{
	NSRect rect = [self getBorder:margin];
	
	float radius = 5.0;

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

- (void) drawBorder
{
	NSRect rect = [self getBorder:4];
	
	float radius = 2;

	radius = MIN(radius, 0.5f * MIN(NSWidth(rect), NSHeight(rect)));
	
	[[NSColor grayColor] setFill];

	NSBezierPath * path = [NSBezierPath bezierPath];
	
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
	rect = [self frame];

	[imageView setFrame:NSMakeRect (margin, margin, (rect.size.width - margin - margin), 
		(rect.size.height - margin - margin))];

	if ([[((GalleryView *) [self superview]) selectedBooks] containsObject:currentBook])
		[self drawSelectedBackground];
}

- (BookManagedObject *) getBook
{
	return currentBook;
}

- (void) updateImage
{
	if (image != nil && image != [NSImage imageNamed:@"Books"])
		[image release];

	image = nil;
			
	if (currentBook != nil)
	{
		NSData * data = [currentBook valueForKey:@"coverImage"];
		
		if (data != nil)
		{
			image = [[NSImage alloc] initWithData:data];
		}
		else
			image = [NSImage imageNamed:@"Books"];
	}

	[imageView setImage:image];
}

- (void) setBook:(BookManagedObject *) book
{
	if (currentBook == book)
		return;

	[imageView unbind:@"toolTip"];

	currentBook = book;
	
	if (book != nil)
	{
		[book addObserver:self forKeyPath:@"coverImage" options:NSKeyValueObservingOptionNew context:NULL];
		[book addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
	}

	[self updateImage];
}

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
	context:(void *)context
{
    if ([keyPath isEqual:@"coverImage"])
	{
		if (currentBook != nil)
			[self updateImage];
	}
	else if ([keyPath isEqual:@"title"])
		[imageView setToolTip:[currentBook valueForKey:@"title"]];
}


- (NSView *) hitTest:(NSPoint)aPoint
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
