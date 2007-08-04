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
	
	BookManagedObject * currentBook;
	float margin;

	NSImage * image;
	
	NSTimer * timer;
	BOOL click;
	
	BOOL inited;
}

- (void) setBook:(BookManagedObject *) book;
- (BookManagedObject *) getBook;

@end
