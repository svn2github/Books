//
//  BooksTableViewDelegate.m
//  Books
//
//  Created by Chris Karr on 7/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BooksTableViewDelegate.h"
#import "BooksAppDelegate.h"
#import "SmartListManagedObject.h"

@implementation BooksTableViewDelegate

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
	NSTableView * table = [notification object];

	if (table == booksTable)
		[((BooksAppDelegate *) booksAppDelegate) updateMainPane];
	else if (table == listsTable)
	{
		if (openFilename != nil)
		{
			[spotlightInterface openFile:openFilename];
			[openFilename release];
			openFilename = nil;
		}

		NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];

		if ([prefs boolForKey:@"Separate Lists"])
		{
			[collectionArrayController setSortDescriptors:
				[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"sortName" ascending:YES]]];
		}
		else
		{
			[collectionArrayController setSortDescriptors:
				[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];
		}

		NSArray * selectedObjects = [collectionArrayController selectedObjects];

		if ([selectedObjects count] > 0)
		{
			ListManagedObject * list = [selectedObjects objectAtIndex:0];

			NSDictionary * sorts = [prefs dictionaryForKey:@"Table Sorting"];
	
			if (sorts != nil)
			{
				NSDictionary * desc = [sorts objectForKey:[[[list objectID] URIRepresentation] absoluteString]];

				if (desc != nil)
				{
					BOOL ascend = NO;
				
					if ([[desc valueForKey:@"ascend"] isEqual:@"YES"])
						ascend = YES;

					NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:[desc valueForKey:@"key"] ascending:ascend];

					[booksTable setSortDescriptors:[NSArray arrayWithObject:sort]];
				}
			}
			
			if ([list isKindOfClass:[SmartListManagedObject class]])
			{
				[toolbarDelegate setNewBookAction:nil];
				[toolbarDelegate setEditSmartListAction:NSSelectorFromString(@"editSmartList:")];
				[toolbarDelegate setRemoveBookAction:nil];
				[toolbarDelegate setRemoveListAction:NSSelectorFromString(@"removeList:")];
			}
			else
			{
				[toolbarDelegate setNewBookAction:NSSelectorFromString(@"newBook:")];
				[toolbarDelegate setEditSmartListAction:nil];
				[toolbarDelegate setRemoveBookAction:NSSelectorFromString(@"removeBook:")];
				[toolbarDelegate setRemoveListAction:NSSelectorFromString(@"removeList:")];
			}
		}
		else
		{
			[toolbarDelegate setNewBookAction:nil];
			[toolbarDelegate setEditSmartListAction:nil];
			[toolbarDelegate setRemoveBookAction:nil];
			[toolbarDelegate setRemoveListAction:nil];
		}
	}

	NSArray * books = [((BooksAppDelegate *) booksAppDelegate) getSelectedBooks];
		
	if ([books count] == 1)
	{
		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];
			
		NSData * coverData = [book getCoverImage];
		
		if (coverData != nil)
			[toolbarDelegate setGetCoverAction:NSSelectorFromString (@"getCoverWindow:")];
		else
			[toolbarDelegate setGetCoverAction:nil];
	}
	
	[((BooksAppDelegate *) booksAppDelegate) orderCoverWindowOut];
	[toolbarDelegate setGetCoverLabel:NSLocalizedString (@"Show Cover", nil)];

	[((BooksAppDelegate *) booksAppDelegate) refreshComboBoxes:nil];
	[((BooksAppDelegate *) booksAppDelegate) updateMainPane];
}

- (void) tableView: (NSTableView *) tableView didClickTableColumn: (NSTableColumn *) tableColumn
{
	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
	
	NSDictionary * sorts = [prefs dictionaryForKey:@"Table Sorting"];
	
	if (sorts == nil)
		sorts = [NSDictionary dictionary];
	
	NSMutableDictionary * newSorts = [NSMutableDictionary dictionaryWithDictionary:sorts];
	
	NSArray * descs = [[tableColumn tableView] sortDescriptors];
	
	int selected = [collectionArrayController selectionIndex];
	
	ListManagedObject * currentList = [[collectionArrayController arrangedObjects] objectAtIndex:selected];
	
	if (currentList != nil)
	{
		NSSortDescriptor * sort = [descs objectAtIndex:0];
		
		NSMutableDictionary * desc = [NSMutableDictionary dictionary];
		
		if ([sort ascending])
			[desc setValue:@"YES" forKey:@"ascend"];
		else
			[desc setValue:@"NO" forKey:@"ascend"];

		[desc setValue:[sort key] forKey:@"key"];

		[newSorts setObject:desc forKey:[[[currentList objectID] URIRepresentation] absoluteString]];
	}
	
	[prefs setValue:newSorts forKey:@"Table Sorting"];
}

- (void) save
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	NSArray * tableColumns = [booksTable tableColumns];

	NSMutableArray * columnWidths = [NSMutableArray array];
	
	NSMutableArray * columns = [NSMutableArray arrayWithArray:[defaults objectForKey:@"Display Fields"]];

	int i = 0;
	for (i = [tableColumns count] - 1; i >=0 ; i--)
	{
		NSTableColumn * column = [tableColumns objectAtIndex:i];
		
		NSString * identifier = [column identifier];
		
		int j = 0;
		for (j = 0; j < [columns count]; j++)
		{
			NSDictionary * dict = [columns objectAtIndex:j];
			
			if ([[dict objectForKey:@"Key"] isEqual:identifier])
			{
				[columns removeObject:dict];
				
				[columns insertObject:dict atIndex:0];
			}
		}
		
		[columnWidths insertObject:[NSNumber numberWithFloat:[column width]] atIndex:0];
	}

	[defaults setObject:columnWidths forKey:@"Main Window Column Widths"];
	
	[defaults setObject:columns forKey:@"Display Fields"];

	NSArray * sortDescriptors = [booksTable sortDescriptors];
	NSMutableArray * savedSortDescriptors = [NSMutableArray array];
	
	for (i = 0; i < [sortDescriptors count]; i++)
	{
		NSSortDescriptor * descriptor = [sortDescriptors objectAtIndex:i];

		NSMutableDictionary * values = [NSMutableDictionary dictionary];
		[values setObject:[descriptor key] forKey:@"key"];
		
		if ([descriptor ascending])
			[values setObject:@"yes" forKey:@"ascending"];
		else
			[values setObject:@"no" forKey:@"ascending"];
		
		[savedSortDescriptors addObject:values];
	}

	[defaults setObject:savedSortDescriptors forKey:@"Books Table Sorting"];

}

- (void) restore
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

	NSArray * columnWidths = [defaults arrayForKey:@"Main Window Column Widths"];
	NSArray * tableColumns = [booksTable tableColumns];
	
	if (columnWidths != nil)
	{
		int i = 0;
		for (i = 0; i < [columnWidths count] && i < [tableColumns count]; i++)
		{
			NSNumber * width = [columnWidths objectAtIndex:i];
			[[tableColumns objectAtIndex:i] setWidth:[width floatValue]];
		}
	}

	NSArray * booksSorting = [defaults arrayForKey:@"Books Table Sorting"];

	NSMutableArray * sortDescriptors = [NSMutableArray array];
	
	int j = 0;
	for (j = 0; j < [booksSorting count]; j++)
	{
		NSDictionary * dict = (NSDictionary *) [booksSorting objectAtIndex:j];
		
		NSSortDescriptor * descriptor = nil;
		
		NSString * key = (NSString *) [dict objectForKey:@"key"];
		
		if ([[dict objectForKey:@"ascending"] isEqual:@"yes"])
			descriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
		else
			descriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:NO];
	
		[sortDescriptors addObject:descriptor];
	}

	[booksTable setSortDescriptors:sortDescriptors];

	[listsTable registerForDraggedTypes:[NSArray arrayWithObject:@"Books Book Type"]];

}	

- (void) updateBooksTable
{
	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
	
	NSArray * newColumns = [prefs arrayForKey:@"Display Fields"];

	NSArray * oldColumns = [NSArray arrayWithArray:[listsTable tableColumns]];

	if ([oldColumns count] == 0)
	{
		NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:@"icon"];
		[[column headerCell] setStringValue:@""];
		[column setDataCell:[[NSImageCell alloc] init]];
		[column bind:@"data" toObject:collectionArrayController withKeyPath:@"arrangedObjects.icon" options: nil];
		[column setWidth:16.0];
		[column setResizingMask:NSTableColumnNoResizing];
		
		[listsTable addTableColumn:column];

		column = [[NSTableColumn alloc] initWithIdentifier:@"name"];
		[[column headerCell] setStringValue:@"Lists"];
		[column bind:@"value" toObject:collectionArrayController withKeyPath:@"arrangedObjects.name" options: nil];
		[column setResizingMask:NSTableColumnAutoresizingMask];
		[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
		[listsTable addTableColumn:column];
		[column setWidth:([listsTable frame].size.width - 16)];
		[collectionArrayController setSortDescriptors:
			[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];
	}

	[collectionArrayController setSortDescriptors:
		[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];

	oldColumns = [NSArray arrayWithArray:[booksTable tableColumns]];
	
	int i = 0;
	
	for (i = 0; i < [oldColumns count]; i++)
		[booksTable removeTableColumn:[oldColumns objectAtIndex:i]];

	if ([newColumns count] == 0)
	{
		NSMutableDictionary * title = [NSMutableDictionary dictionary];
		[title setValue:@"title" forKey:@"Key"];
		[title setValue:NSLocalizedString (@"Title", nil) forKey:@"Title"];
		[title setValue:[NSNumber numberWithInt:1] forKey:@"Enabled"];

		newColumns = [NSArray arrayWithObject:title];
	}

	for (i = 0; i < [newColumns count]; i++)
	{
		NSDictionary * dict = [newColumns objectAtIndex:i];

		NSString * key = [dict objectForKey:@"Key"];
		NSString * title = NSLocalizedString ([dict objectForKey:@"Title"], nil);
		NSString * enabled = [[dict objectForKey:@"Enabled"] description];

		if ([enabled isEqualToString:@"1"])
		{
			NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:key];
		
			[[column headerCell] setStringValue:title];
			[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
			
			[column bind:@"value" toObject:bookArrayController withKeyPath:[@"arrangedObjects." stringByAppendingString:key] 
			options: nil];
			

			NSString * dateFormat = [[NSUserDefaults standardUserDefaults] stringForKey:@"Custom Date Format"];
			[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
			NSDateFormatter * formatter;
			
			if (dateFormat != nil)
				formatter = [[NSDateFormatter alloc] initWithDateFormat:dateFormat allowNaturalLanguage:YES];
			else
			{
				formatter = [[NSDateFormatter alloc] initWithDateFormat:@"%B %e, %Y" allowNaturalLanguage:YES];
				[formatter setDateStyle:NSDateFormatterLongStyle];
			}

			if ([key isEqualToString:@"publishDate"] || 
				[key isEqualToString:@"dateLent"] ||
				[key isEqualToString:@"dateDue"] ||
				[key isEqualToString:@"dateFinished"] ||
				[key isEqualToString:@"dateAcquired"] ||
				[key isEqualToString:@"dateStarted"] )
			{
				[[column dataCell] setFormatter:formatter];

				NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
				
				[column setSortDescriptorPrototype:sortDescriptor];
			}
			else
			{
				NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
				
				[column setSortDescriptorPrototype:sortDescriptor];
			}

			[column setEditable:NO];
			
			[booksTable addTableColumn:column];
		}
	}

	
	NSString * customString = [prefs objectForKey:@"Custom List User Fields"];

	if (customString != nil && ![customString isEqual:@""])
	{
		NSArray * fields = [customString componentsSeparatedByString:@"\n"];

		for (i = 0; i < [fields count]; i++)
		{
			NSString * field = [fields objectAtIndex:i];

			NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:field];
		
			[[column headerCell] setStringValue:field];
			[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
			
			[column bind:@"value" toObject:bookArrayController 
				withKeyPath:[@"arrangedObjects." stringByAppendingString:field] options: nil];
			
			NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:field ascending:YES];
				
			[column setSortDescriptorPrototype:sortDescriptor];

			[column setEditable:NO];
			
			[booksTable addTableColumn:column];
		}
	}		
	
	[booksTable setDoubleAction:@selector(getInfoWindow:)];
}

- (void) reloadListsTable
{
	[listsTable reloadData];
}

- (void) reloadBooksTable
{
	[booksTable reloadData];
}

- (NSTableView *) getListsTable
{
	return listsTable;
}

- (NSTableView *) getBooksTable
{
	return booksTable;
}

- (void) setOpenFilename:(NSString *) filename
{
	openFilename = [filename retain];
}

@end
