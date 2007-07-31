//
//  GalleryControlView.m
//  Books
//
//  Created by Chris Karr on 7/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GalleryControlView.h"
#import "GalleryView.h"

@implementation GalleryControlView

- (id)initWithFrame:(NSRect)frame 
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		tag = -1;
	}
	return self;
}

- (void) drawRect: (NSRect)rect 
{
	if (tag == -1)
	{
		NSRect r = NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height);
		tag = [self addTrackingRect:r owner:self userData:nil assumeInside:YES]; 
	}

	float radius = 6.0;
	radius = MIN(radius, 0.5f * MIN(NSWidth(rect), NSHeight(rect)));
	
	[[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:0.1 alpha:0.8] setFill];

	NSBezierPath* path = [NSBezierPath bezierPath];
	
	rect = NSInsetRect(rect, radius, radius);
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0 endAngle: 90.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0 endAngle:180.0];
	[path closePath];
	
	[path fill];
}

- (void) mouseExited:(NSEvent *)theEvent
{
	timer = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:NSSelectorFromString(@"hideControl:") 
		userInfo:nil repeats:NO] retain];
}

- (void) mouseEntered:(NSEvent *)theEvent
{
	[timer invalidate];
	[timer release];
}

- (void) hideControl:(NSTimer*) theTimer
{
	NSNotification * notification = [NSNotification notificationWithName:GALLERY_HIDE_CONTROL object:nil];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)viewDidEndLiveResize
{
	[self removeTrackingRect:tag];
	tag = -1;
}

@end
