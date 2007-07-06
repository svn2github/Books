//
//  BooksTableViewDelegate.h
//  Books
//
//  Created by Chris Karr on 7/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BooksToolbarDelegate.h"
#import "BooksSpotlightInterface.h"

@interface BooksTableViewDelegate : NSObject 
{
	IBOutlet NSTableView * booksTable;
	IBOutlet NSTableView * listsTable;
	
	IBOutlet NSObject * booksAppDelegate;
	IBOutlet BooksToolbarDelegate * toolbarDelegate;
	IBOutlet BooksSpotlightInterface * spotlightInterface;

	IBOutlet NSArrayController * collectionArrayController;
	IBOutlet NSArrayController * bookArrayController;
	
	NSString * openFilename;
}

- (void) save;
- (void) restore;
- (void) updateBooksTable;
- (void) reloadListsTable;
- (void) reloadBooksTable;

- (NSTableView *) getListsTable;
- (NSTableView *) getBooksTable;

- (void) setOpenFilename:(NSString *) filename;

@end