//
//  GalleryView.h
//  Books
//
//  Created by Chris Karr on 7/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GalleryControlView.h"
#import "GalleryIconView.h"
#import "BookManagedObject.h"

#define GALLERY_HIDE_CONTROL @"Books Gallery Hide Control"
#define GALLERY_SHOW_CONTROL @"Books Gallery Show Control"

@interface GalleryView : NSView 
{
	IBOutlet NSArrayController * bookList;

	IBOutlet GalleryControlView * controlView;
	IBOutlet GalleryIconView * icon;
	
	IBOutlet NSSlider * pages;

	IBOutlet NSTextField * text;
	
	int page;
	int count;

	NSArray * selectedBooks;
	
	BOOL controlVisible;
}

- (void) setSelectedBook:(BookManagedObject *) b;
- (NSArray *) selectedBooks;

@end
