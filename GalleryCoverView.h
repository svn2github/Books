//
//  GalleryCoverView.h
//  Books
//
//  Created by Chris Karr on 7/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BookManagedObject.h";

@interface GalleryCoverView : NSView 
{
	NSImageView * imageView;
	NSImage * image;
	
	BookManagedObject * currentBook;
	float margin;
	
	NSTrackingRectTag tag;
	BOOL hover;
}

- (void) setBook:(BookManagedObject *) book;

@end
