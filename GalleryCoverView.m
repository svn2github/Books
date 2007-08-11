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
#import "SmartListManagedObject.h"

@implementation GalleryCoverView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];

    if (self) 
	{
		margin = 6;

		imageView = [[NSImageView alloc] init];
		[imageView setImageScaling:NSScaleToFit];
		[imageView setImageFrameStyle:NSImageFramePhoto];
		[self addSubview:imageView];
		[imageView setHidden:NO];

		cachedData = nil;
		currentBook = nil;
		
		timer = nil;
		click = false;
  }
    return self;
}

- (NSRect) getBorder:(float) borderWidth
{
	NSSize borderSize = [imageView frame].size;
	
	NSSize viewSize = [self frame].size;

	borderSize.width += borderWidth;
	borderSize.height += borderWidth;
	
	float x = (viewSize.width - borderSize.width) / 2;
	float y = (viewSize.height - borderSize.height) / 2;

	NSRect rect = NSMakeRect (x, y, borderSize.width, borderSize.height); 

	return rect;
}

- (void) setImageViewFrame
{
	NSSize frameSize = [self frame].size;
	
	NSImage * img = [imageView image];
	NSSize imageSize = [img size];
	NSSize viewSize = [self frame].size;
	
	viewSize.width -= margin * 2;
	viewSize.height -= margin * 2;
	
	if (imageSize.width > viewSize.width || imageSize.height > viewSize.height)
	{
		float ratio = imageSize.height / imageSize.width;
		
		if (ratio < 1)
		{
			ratio = viewSize.width / imageSize.width;
			viewSize.width = viewSize.width;
			viewSize.height = imageSize.height * ratio;
		}
		else
		{
			ratio = viewSize.height / imageSize.height;
			viewSize.width = imageSize.width * ratio;
			viewSize.height = viewSize.height;
		}
	}
	else
	{
		viewSize = imageSize;
	}
	
	viewSize.width = (float) ((int) viewSize.width) + 2;
	viewSize.height = (float) ((int) viewSize.height) + 2;

	float x = (frameSize.width - viewSize.width) / 2;
	float y = (frameSize.height - viewSize.height) / 2;
	
	[imageView setFrame:NSMakeRect (x, y, viewSize.width, viewSize.height)];
}

- (void) drawSelectedBackground
{
	NSRect rect = [self getBorder:margin];
	
	float radius = 0.0;

	[[NSColor alternateSelectedControlColor] setStroke];

	NSBezierPath * path = [NSBezierPath bezierPath];
	[path setLineWidth:(margin / 2) - 1];
	
	rect = NSInsetRect(rect, radius, radius);
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0 endAngle: 90.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0 endAngle:180.0];
	[path closePath];
	
	[path stroke];
}

- (void)drawRect:(NSRect)rect
{
	rect = [self frame];

	[self setImageViewFrame];

	GalleryView * gv = (GalleryView *) [self superview];
	
	if ([gv isSelected:currentBook])
		[self drawSelectedBackground];
}

- (void) updateImage
{
	if (currentBook != nil)
	{
		NSData * data = [currentBook valueForKey:@"coverImage"];
		
		if ((cachedData == nil || ![cachedData isEqualToData:data]) && data != nil)
		{
			NSImage * image = [[NSImage alloc] initWithData:data];
			[imageView setImage:image];
			[imageView setImageFrameStyle:NSImageFramePhoto];
			[image release];
			
			if (cachedData != nil)
				[cachedData release];
				
			cachedData = [[NSData alloc] initWithData:data];
		}
		else
		{
			[imageView setImage:[NSImage imageNamed:@"Books"]];
			[imageView setImageFrameStyle:NSImageFrameNone];
		}
	}
	else
		[imageView setImage:nil];

	[self setNeedsDisplay:YES];
}

- (void) setBook:(BookManagedObject *) book
{
	if (currentBook == book)
		return;

	if (cachedData != nil)
		[cachedData release];

	cachedData = nil;

	[currentBook removeObserver:self forKeyPath:@"coverImage"];
	[currentBook removeObserver:self forKeyPath:@"title"];
	
	currentBook = [book retain];
	
	if (currentBook != nil)
	{
		[currentBook addObserver:self forKeyPath:@"coverImage" options:NSKeyValueObservingOptionNew context:NULL];
		[currentBook addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
	}

	[self updateImage];
	[self setNeedsDisplay:YES];
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
	
	if (p.x >= 0 && myFrame.width >= p.x && p.y >= 0 && myFrame.height >= p.y)
		return self;
	
	return [super hitTest:aPoint];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void) resetClick:(NSTimer*) theTimer
{
	click = false;

	[timer invalidate];
	[timer release];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	GalleryView * gv = (GalleryView *) [self superview];
	
	[gv setSelectedView:self];

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


- (NSMenu *) menuForEvent:(NSEvent *)theEvent
{
	GalleryView * gv = (GalleryView *) [self superview];
	
	[gv setSelectedView:self];

	ListManagedObject * obj = [[[((GalleryView *) [self superview] ) listController] selectedObjects] objectAtIndex:0];

	NSMenu * menu = [[NSMenu alloc] init];

	if ([obj isKindOfClass:[SmartListManagedObject class]])
		[menu addItemWithTitle:NSLocalizedString (@"No operations available", nil) action:nil keyEquivalent:@""];
	else
	{
		[menu addItemWithTitle:NSLocalizedString (@"Duplicate", nil) action:NSSelectorFromString(@"duplicateRecords:") keyEquivalent:@""];
		[menu addItemWithTitle:NSLocalizedString (@"Delete", nil) action:NSSelectorFromString(@"removeBook:") keyEquivalent:@""];
		[menu addItem:[NSMenuItem separatorItem]];

		[menu addItemWithTitle:NSLocalizedString (@"New Book", nil) action:NSSelectorFromString(@"newBook:") keyEquivalent:@""];
	}

	return menu;
}

@end
