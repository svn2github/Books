//
//  GalleryView.h
//  Books
//
//  Created by Chris Karr on 7/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GalleryControlView.h"
#import "BookManagedObject.h"

@interface GalleryView : NSView 
{
	IBOutlet NSArrayController * bookList;

	IBOutlet GalleryControlView * controlView;
	IBOutlet NSSlider * pages;

	IBOutlet NSTextField * text;
	
	int page;
	int count;

	NSArray * selectedBooks;
}

- (void) setSelectedBook:(BookManagedObject *) b;
- (NSArray *) selectedBooks;

@end
