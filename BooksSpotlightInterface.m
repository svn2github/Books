//
//  BooksSpotlightInterface.m
//  Books
//
//  Created by Chris Karr on 7/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BooksSpotlightInterface.h"
#import "SmartListManagedObject.h"
#import "BookManagedObject.h"
#import "BooksAppDelegate.h"

@implementation BooksSpotlightInterface

- (void) loadDataFromOutside:(NSData *) data
{
	NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;

	NSString * error = nil;
	
	NSDictionary * metadata = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable 
									format:&format errorDescription:&error];

	NSArray * lists = [collectionArrayController arrangedObjects];
	

	NSLog (@"looking for list %@", [metadata valueForKey:@"listName"]);

	int i = 0;
	for (i = 0; i < [lists count]; i++)
	{
		NSString * name = [[lists objectAtIndex:i] valueForKey:@"name"];
		
		if ([name isEqualToString:[metadata valueForKey:@"listName"]])
			[collectionArrayController setSelectedObjects:[NSArray arrayWithObject:[lists objectAtIndex:i]]];
	}

	NSLog (@"looking for book %@", [metadata valueForKey:@"id"]);
	
	NSArray * books = [bookArrayController arrangedObjects];
	
	for (i = 0; i < [books count]; i++)
	{
		NSString * id = [[books objectAtIndex:i] valueForKey:@"id"];
		
		if ([id isEqualToString:[metadata valueForKey:@"id"]])
		{
			[bookArrayController setSelectedObjects:[NSArray arrayWithObject:[books objectAtIndex:i]]];
		}
	}
}

- (IBAction) updateSpotlightIndex:(id) sender
{
	[((BooksAppDelegate *) booksAppDelegate) startProgressWindow:NSLocalizedString (@"Updating Spotlight index...", nil)];

	NSArray * lists = [collectionArrayController arrangedObjects];
	
	int i = 0;
	for (i = 0; i < [lists count]; i++)
	{
		ListManagedObject * list = [lists objectAtIndex:i];
		
		if (![list isKindOfClass:[SmartListManagedObject class]])
		{
			NSArray * books = [list getBooks];
	
			int j = 0;
			for (j = 0; j < [books count]; j++)
			{
				BookManagedObject * book = [books objectAtIndex:j];
				
				[book writeSpotlightFile];
			}
		}
	}

	[((BooksAppDelegate *) booksAppDelegate) endProgressWindow];
}

- (IBAction) clearSpotlightIndex:(id) sender
{
	BOOL isDir;
	NSString * path = [NSString stringWithFormat:@"%@%@", NSHomeDirectory (),
						@"/Library/Caches/Metadata/Books"];

	NSFileManager * manager = [NSFileManager defaultManager];

	if ([manager fileExistsAtPath:path isDirectory:&isDir])
		[manager removeFileAtPath:path handler:nil];
}

- (BOOL) openFile:(NSString *) filename
{
	NSData * fileData = [NSData dataWithContentsOfFile:filename];
	[self loadDataFromOutside:fileData];
	
	return YES;
}

@end
