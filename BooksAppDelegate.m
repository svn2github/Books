/*
   Copyright (c) 2006 Chris J. Karr

   Permission is hereby granted, free of charge, to any person 
   obtaining a copy of this software and associated documentation 
   files (the "Software"), to deal in the Software without restriction, 
   including without limitation the rights to use, copy, modify, merge, 
   publish, distribute, sublicense, and/or sell copies of the Software, 
   and to permit persons to whom the Software is furnished to do so, 
   subject to the following conditions:

   The above copyright notice and this permission notice shall be 
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
   SOFTWARE.
*/


#import "BooksAppDelegate.h"
#import "ImportPluginInterface.h"
#import "ExportPluginInterface.h"
#import "QuickfillPluginInterface.h"
#import "HtmlPageBuilder.h"
#import "SmartListManagedObject.h"
#import "BookManagedObject.h"
#import "MyBarcodeScanner.h"
#import "CoverWindowDelegate.h"
#import "NotificationInterface.h"

typedef struct _monochromePixel
{ 
	unsigned char grayValue; 
	unsigned char alpha; 
} monochromePixel;
	
@implementation BooksAppDelegate

- (NSManagedObjectModel *) managedObjectModel 
{
    if (managedObjectModel) 
		return managedObjectModel;
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
	[allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];

    [allBundles release];
    
    return managedObjectModel;
}

- (NSString *) applicationSupportFolder 
{
    NSString * applicationSupportFolder = nil;
    FSRef foundRef;
    OSErr err = FSFindFolder (kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);

    if (err != noErr) 
	{
        NSRunAlertPanel (NSLocalizedString (@"Alert", nil), NSLocalizedString (@"Can't find application support folder", nil), 
							NSLocalizedString (@"Quit", nil), nil, nil);
        [[NSApplication sharedApplication] terminate:self];
    }
	else 
	{
        unsigned char path[1024];
        FSRefMakePath (&foundRef, path, sizeof(path));
        applicationSupportFolder = [NSString stringWithUTF8String:(char *) path];
        applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:@"Books"];
    }
	
    return applicationSupportFolder;
}

- (NSManagedObjectContext *) managedObjectContext
{
    NSError * error;
    NSString * applicationSupportFolder = nil;
    NSURL * url;
    NSFileManager * fileManager;
    NSPersistentStoreCoordinator * coordinator;
    
    if (managedObjectContext) 
	{
        return managedObjectContext;
    }
    
	fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    
	if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) 
	{
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
	NSString * filePath = [applicationSupportFolder stringByAppendingPathComponent: @"Books.books-data"];
	
    url = [NSURL fileURLWithPath:filePath];
    
	coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    if ([coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error])
	{
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
	else
	{
        [[NSApplication sharedApplication] presentError:error];
    }
	    
    [coordinator release];

	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];

	NSEntityDescription * entity = [NSEntityDescription entityForName:@"List" inManagedObjectContext:managedObjectContext];

	[fetch setEntity:entity];
	[fetch setPredicate:[NSPredicate predicateWithFormat:@"name != \"\""]];

	NSArray * results = [[self managedObjectContext] executeFetchRequest:fetch error:&error];

	if (results == nil || [results count] == 0)
	{
		NSEntityDescription * collectionDesc = [[[self managedObjectModel] entitiesByName] objectForKey:@"List"];
		NSEntityDescription * bookDesc = [[[self managedObjectModel] entitiesByName] objectForKey:@"Book"];

		[managedObjectContext lock];
		
		ListManagedObject * listObject = [[ListManagedObject alloc] initWithEntity:collectionDesc 
											insertIntoManagedObjectContext:managedObjectContext];

		[listObject setValue:NSLocalizedString (@"My Books", nil) forKey:@"name"];

		NSMutableSet * items = [listObject mutableSetValueForKey:@"items"];
		
		BookManagedObject * bookObject = [[BookManagedObject alloc] initWithEntity:bookDesc insertIntoManagedObjectContext:managedObjectContext];

		[bookObject setValue:NSLocalizedString (@"New Book", nil) forKey:@"title"];
		[items addObject:bookObject];

		[managedObjectContext unlock];
	}

    return managedObjectContext;
}

- (NSUndoManager *) windowWillReturnUndoManager: (NSWindow *) window 
{
    return [[self managedObjectContext] undoManager];
}

- (IBAction) saveAction:(id) sender 
{
    NSError *error = nil;

    if (![[self managedObjectContext] save:&error]) 
	{
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) sender 
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

	[tableViewDelegate save];

	NSMutableArray * viewRects = [NSMutableArray array];
	NSEnumerator * viewEnum = [[splitView subviews] objectEnumerator];
	NSView * view;

	while ((view = [viewEnum nextObject]) != nil)
	{
		NSRect frame;
		
		if ([splitView isSubviewCollapsed: view])
			frame = NSZeroRect;
		else
			frame = [view frame];

		[viewRects addObject:NSStringFromRect (frame)];
	}

	[defaults setObject:viewRects forKey:@"Main Scroller Sizes"];

	viewRects = [NSMutableArray array];
	viewEnum = [[leftView subviews] objectEnumerator];

	while ((view = [viewEnum nextObject]) != nil)
	{
		NSRect frame;
		
		if ([leftView isSubviewCollapsed:view])
			frame = NSZeroRect;
		else
			frame = [view frame];

		[viewRects addObject:NSStringFromRect (frame)];
	}

	[defaults setObject:viewRects forKey:@"Left Scroller Sizes"];

	viewRects = [NSMutableArray array];
	viewEnum = [[rightView subviews] objectEnumerator];

	while ((view = [viewEnum nextObject]) != nil)
	{
		NSRect frame;
		
		if ([rightView isSubviewCollapsed:view])
			frame = NSZeroRect;
		else
			frame = [view frame];

		[viewRects addObject:NSStringFromRect (frame)];
	}

	[defaults setObject:viewRects forKey:@"Right Scroller Sizes"];

    NSError *error;
    NSManagedObjectContext *context;
    int reply = NSTerminateNow;
    
    context = [self managedObjectContext];

    if (context != nil) 
	{
		if ([context commitEditing])
		{
			if (![context save:&error]) 
			{
				// This default error handling implementation should be changed to make sure the error presented 
				// includes application specific error recovery. For now, simply display 2 panels.
                
				BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
				if (errorResult == YES)
				{
					// Then the error was handled
					reply = NSTerminateCancel;
				} 
				else 
				{
					// Error handling wasn't implemented. Fall back to displaying a "quit anyway" panel.
					int alertReturn = NSRunAlertPanel (nil, NSLocalizedString (@"Could not save changes while quitting. Quit anyway?", nil) , 
													NSLocalizedString (@"Quit anyway", nil), NSLocalizedString (@"Cancel", nil), nil);
					
					if (alertReturn == NSAlertAlternateReturn)
					{
						reply = NSTerminateCancel;	
					}
				}
			}
        }
		else 
		{
            reply = NSTerminateCancel;
        }
    }
	
	if (reply != NSTerminateCancel)
	{
		BOOL isDir;

		NSFileManager * manager = [NSFileManager defaultManager];

		if ([manager fileExistsAtPath:@"/tmp/books-export" isDirectory:&isDir])
			[manager removeFileAtPath:@"/tmp/books-export" handler:nil];

		if ([manager fileExistsAtPath:@"tmp/books-quickfill.xml" isDirectory:&isDir])
			[manager removeFileAtPath:@"tmp/books-quickfill.xml" handler:nil];
	}

    return reply;
}

- (NSWindow *) mainWindow
{
	return mainWindow;
}

- (NSWindow *) infoWindow
{
	return infoWindow;
}

- (IBAction) getInfoWindow: (id) sender
{
	if ([infoWindow isVisible])
	{
		[infoWindow orderOut:sender];
		[toolbarDelegate setGetInfoLabel:NSLocalizedString (@"Get Info", nil)];
	}
	else
	{
		[infoWindow makeKeyAndOrderFront:sender];
		[toolbarDelegate setGetInfoLabel:NSLocalizedString (@"Hide Info", nil)];
	}
}


- (IBAction) getCoverWindow: (id) sender
{
	if ([coverWindow isVisible])
	{
		[coverWindow orderOut:sender];
		[toolbarDelegate setGetCoverLabel:NSLocalizedString (@"Show Cover", nil)];
	}
	else
	{
		NSArray * books = [self getSelectedBooks];
		
		if ([books count] == 1)
		{
			BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];
			
			NSData * coverData = [book getCoverImage];
		
			if (coverData != nil)
			{
/*				NSImage * cover = [[NSImage alloc] initWithData:coverData];
				
				[detailedCoverView setValue:cover forInputKey:@"Image"];
				
				// [coverWindow makeKeyAndOrderFront:sender];
*/
				[coverWindow orderFront:sender];
				[toolbarDelegate setGetCoverLabel:NSLocalizedString (@"Hide Cover", nil)];
			}
		}
	}
}


- (IBAction) doExport:(id) sender
{
	ExportPluginInterface * export = [[ExportPluginInterface alloc] init];
	
	NSBundle * exportPlugin = nil;
	
	[NSThread detachNewThreadSelector:NSSelectorFromString(@"ExportToBundle") toTarget:export withObject:exportPlugin];
}

- (void) awakeFromNib
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	NSToolbar * tb = [[NSToolbar alloc] initWithIdentifier:@"main"];
	
	[tb setDelegate:toolbarDelegate];
	[tb setAllowsUserCustomization:YES];
	[tb setAutosavesConfiguration:YES];
	
	[mainWindow setToolbar:tb];
	
	[tableViewDelegate updateBooksTable];
	[tableViewDelegate restore];

	NSString * dateFormat = [self getDateFormatString];

	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];

	NSDateFormatter * formatter = [[NSDateFormatter alloc] initWithDateFormat:dateFormat allowNaturalLanguage:YES];
	[[datePublished cell] setFormatter:formatter];


	/* Resize Main Scroller */
	
	NSArray * viewRects = [defaults objectForKey:@"Main Scroller Sizes"];
	
	if (viewRects != nil)
	{
		NSArray * views = [splitView subviews];
        int i, count;

        count = MIN ([viewRects count], [views count]);

        for(i = 0; i < count; i++)
        {
			NSRect frame = NSRectFromString ([viewRects objectAtIndex:i]);

			if (NSIsEmptyRect (frame))
			{
				frame = [[views objectAtIndex:i] frame];
                        
				if([splitView isVertical])
					frame.size.width = 0;
				else
					frame.size.height = 0;
			}

			[[views objectAtIndex:i] setFrame:frame];
		}
	}

	viewRects = [defaults objectForKey:@"Left Scroller Sizes"];
	
	if (viewRects != nil)
	{
		NSArray * views = [leftView subviews];
        int i, count;

        count = MIN ([viewRects count], [views count]);

        for(i = 0; i < count; i++)
        {
			NSRect frame = NSRectFromString ([viewRects objectAtIndex:i]);

			if (NSIsEmptyRect (frame))
			{
				frame = [[views objectAtIndex:i] frame];
                        
				if([leftView isVertical])
					frame.size.width = 0;
				else
					frame.size.height = 0;
			}

			[[views objectAtIndex:i] setFrame:frame];
		}
	}

	viewRects = [defaults objectForKey:@"Right Scroller Sizes"];
	
	if (viewRects != nil)
	{
		NSArray * views = [rightView subviews];
        int i, count;

        count = MIN ([viewRects count], [views count]);

        for(i = 0; i < count; i++)
        {
			NSRect frame = NSRectFromString ([viewRects objectAtIndex:i]);

			if (NSIsEmptyRect (frame))
			{
				frame = [[views objectAtIndex:i] frame];
                        
				if([rightView isVertical])
					frame.size.width = 0;
				else
					frame.size.height = 0;
			}

			[[views objectAtIndex:i] setFrame:frame];
		}
	}

	NSString * filePath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory (),
								@"/Library/Application Support/Books/Files/", nil];

	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
		[[NSFileManager defaultManager] createDirectoryAtPath:filePath attributes:nil];

	[imageView setTarget:self];
	[imageView setAction:@selector(getCoverWindow:)];

	[mainWindow setShowsResizeIndicator:NO];
	[mainWindow setMovableByWindowBackground:YES];
	
	[coverWindow setReleasedWhenClosed:NO];
	[coverWindow setCanHide:YES];
	
	[coverWindow setDelegate:[[CoverWindowDelegate alloc] init]];
	
	[mainWindow makeKeyAndOrderFront:self];
	
	[summary setFieldEditor:NO];
	[self updateMainPane];

	[NotificationInterface start];
	
	[mainWindow setTitle:NSLocalizedString (@"Books - Loading...", nil)];
	// [[[NSApplication sharedApplication] delegate] startProgressWindow:NSLocalizedString (@"Loading data from disk...", nil)];
}

- (void) startProgressWindow: (NSString *) message
{
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator startAnimation:self];
	[progressText setStringValue:message];
	
	[[NSApplication sharedApplication] beginSheet:progressView modalForWindow:mainWindow
		modalDelegate:self didEndSelector:nil contextInfo:NULL];
}

- (void) endProgressWindow
{
	[[NSApplication sharedApplication] endSheet:progressView];
	[progressView orderOut:self];

	[progressIndicator stopAnimation:self];
}

- (void) updateMainPane
{
	WebFrame * mainFrame = [detailsPane mainFrame];

	NSArray * selectedObjects = [bookArrayController selectedObjects];
	NSURL * localhost = [NSURL URLWithString:@"http://localhost/"];
	
	if (pageBuilder == nil)
		pageBuilder = [[HtmlPageBuilder alloc] init];

	NSString * htmlString = [pageBuilder buildEmptyPage];		

	if ([selectedObjects count] == 1)
	{
		BookManagedObject * object = [selectedObjects objectAtIndex:0];
		
		htmlString = [pageBuilder buildPageForObject:object];
	}
	else if ([selectedObjects count] > 1)
		htmlString = [pageBuilder buildPageForArray:selectedObjects];

	[mainFrame loadHTMLString:htmlString baseURL:localhost];
}


- (void) refreshComboBoxes: (NSArray *) books
{
	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"Book" inManagedObjectContext:[self managedObjectContext]]];

	NSError * error = nil;
	books = [[self managedObjectContext] executeFetchRequest:fetch error:&error];
		
	NSMutableSet * userFieldNames = [NSMutableSet set];

	[tokenDelegate updateTokens];
	[comboBoxDelegate updateTokens];

	int i = 0;
	for (i = 0; i < [books count]; i++)
	{
		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:i];
		
		NSMutableSet * userFields = [book mutableSetValueForKey:@"userFields"];
		NSArray * allFields = [userFields allObjects];
		
		int j = 0;
		for (j = 0; j < [allFields count]; j++)
		{
			NSManagedObject * field = [allFields objectAtIndex:j];
			
			NSString * fieldString = [field valueForKey:@"key"];
			
			if (fieldString != nil)
				[userFieldNames addObject:fieldString];
		}
	}

	NSArray * lists = [NSArray arrayWithObjects: userFieldNames, nil];
	NSArray * listCombos = [NSArray arrayWithObjects: userFieldCombo, nil];

	for (i = 0; i < [lists count] && i < [listCombos count]; i++)
	{
		[[listCombos objectAtIndex:i] removeAllItems];

		NSMutableArray * array = [NSMutableArray arrayWithArray:[[lists objectAtIndex:i] allObjects]];
		[array sortUsingSelector:@selector(compare:)];
		
		[[listCombos objectAtIndex:i] addItemsWithObjectValues:array];
	}
}

- (IBAction)preferences:(id)sender
{
	if ([preferencesWindow isVisible])
		[preferencesWindow orderOut:sender];
	else
		[preferencesWindow makeKeyAndOrderFront:sender];
}

- (NSArray *) getQuickfillPlugins
{
	if (quickfillPlugins == nil)
		[self initQuickfillPlugins];

	return [[quickfillPlugins allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void) setQuickfillPlugins: (NSArray *) list
{

}

- (void) initQuickfillPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [NSHomeDirectory () stringByAppendingPathComponent:appSupport];
	NSString * sysPath = [@"/" stringByAppendingPathComponent:appSupport];

	NSArray * paths = [NSArray arrayWithObjects:appPath, sysPath, userPath, nil];

	NSEnumerator * pathEnum = [paths objectEnumerator];

	NSString * path;
 
	quickfillPlugins = [[NSMutableDictionary alloc] init];
 
	while (path = [pathEnum nextObject])
	{
		NSEnumerator * e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];

		NSString * name;

		while (name = [e nextObject])
		{
			if ([[name pathExtension] isEqualToString:@"plugin"])
			{
				NSBundle * plugin = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:name]];
				
				NSDictionary * pluginDict = [plugin infoDictionary];
				
				if ([[pluginDict objectForKey:@"BooksPluginType"] isEqual:@"Quickfill"])
				{
					NSString * pluginName = (NSString *) [[pluginDict objectForKey:@"BooksPluginName"] copy];

					[quickfillPlugins setObject:plugin forKey:pluginName];
				}
			}
		}
	}
}

- (IBAction) quickfill: (id)sender
{
	if (quickfillPlugins == nil)
		[self initQuickfillPlugins];
		
	NSString * pluginKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"Default Quickfill Plugin"];

	if (pluginKey == nil || [pluginKey isEqualToString:@""])
	{
		NSRunAlertPanel (NSLocalizedString (@"No Quickfill Plugin Selected", nil),  
			NSLocalizedString (@"No quickfill plugins have been selected. Select one in the preferences.", nil), NSLocalizedString (@"OK", nil), nil, nil);
		
		return;
	}

	NSArray * books = [self getSelectedBooks];

	if (books != nil && [books count] == 1)
	{
		[self startQuickfill];

		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];
		NSBundle * quickfillPlugin = (NSBundle *) [quickfillPlugins objectForKey:pluginKey];

		if (quickfillPlugin == nil)
		{
			[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"Default Quickfill Plugin"];
			[self quickfill:sender];
			return;
		}

		quickfill = [[QuickfillPluginInterface alloc] init];

		[quickfill importFromBundle:quickfillPlugin forBook:book replace:NO];
	}
	else
		NSRunAlertPanel (NSLocalizedString (@"Too Many Books Selected", nil),  NSLocalizedString (@"Only one book may be quickfilled at a time.", nil), NSLocalizedString (@"OK", nil), nil, nil);
}

- (void) startQuickfill
{
	if ([infoWindow isVisible])
	{
		[quickfillProgress startAnimation:self];
		[NSApp beginSheet:quickfillWindow modalForWindow:infoWindow modalDelegate:self didEndSelector:nil contextInfo:NULL];
	}
}

- (IBAction) cancelQuickfill: (id) sender
{
	if (quickfill != nil)
		[quickfill killTask];
}

- (void) stopQuickfill
{
	[quickfill release];
	quickfill = nil;
	
	if ([infoWindow isVisible])
	{
		[NSApp endSheet:quickfillWindow];

		[quickfillWindow orderOut:self];
		[quickfillProgress stopAnimation:self];
	}
}

- (NSArray *) getImportPlugins
{
	if (importPlugins == nil)
		[self initImportPlugins];

	return [[importPlugins allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void) initImportPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [NSHomeDirectory () stringByAppendingPathComponent:appSupport];
	NSString * sysPath = [@"/" stringByAppendingPathComponent:appSupport];

	NSArray * paths = [NSArray arrayWithObjects:appPath, sysPath, userPath, nil];

	NSEnumerator * pathEnum = [paths objectEnumerator];

	NSString * path;
 
	importPlugins = [[NSMutableDictionary alloc] init];
 
	while (path = [pathEnum nextObject])
	{
		NSEnumerator * e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];

		NSString * name;

		while (name = [e nextObject])
		{
			if ([[name pathExtension] isEqualToString:@"app"])
			{
				NSBundle * plugin = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:name]];
				
				NSDictionary * pluginDict = [plugin infoDictionary];
				
				if ([[pluginDict objectForKey:@"BooksPluginType"] isEqual:@"Import"])
				{
					NSString * pluginName = (NSString *) [[pluginDict objectForKey:@"BooksPluginName"] copy];

					[importPlugins setObject:plugin forKey:pluginName];
				}
			}
		}
	}
}

- (void) setImportPlugins: (NSArray *) list
{

}

- (IBAction) import: (id)sender
{
	if (importPlugins == nil)
		[self initImportPlugins];
		
	NSString * pluginKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"Default Import Plugin"];

	if (pluginKey == nil || [pluginKey isEqualToString:@""])
	{
		// NSAlert
		
		return;
	}

	NSBundle * importPlugin = (NSBundle *) [importPlugins objectForKey:pluginKey];
	
	ImportPluginInterface * import = [[ImportPluginInterface alloc] init];
	
	[NSThread detachNewThreadSelector:NSSelectorFromString(@"importFromBundle:") toTarget:import withObject:importPlugin];
}

- (NSArray *) getExportPlugins
{
	if (exportPlugins == nil)
		[self initExportPlugins];
		
	return [[exportPlugins allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void) setExportPlugins: (NSArray *) list
{

}

- (void) initExportPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [NSHomeDirectory () stringByAppendingPathComponent:appSupport];
	NSString * sysPath = [@"/" stringByAppendingPathComponent:appSupport];

	NSArray * paths = [NSArray arrayWithObjects:appPath, sysPath, userPath, nil];

	NSEnumerator * pathEnum = [paths objectEnumerator];

	NSString * path;
 
	exportPlugins = [[NSMutableDictionary alloc] init];
 
	while (path = [pathEnum nextObject])
	{
		NSEnumerator * e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];

		NSString * name;

		while (name = [e nextObject])
		{
			if ([[name pathExtension] isEqualToString:@"app"])
			{
				NSBundle * plugin = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:name]];
				
				NSDictionary * pluginDict = [plugin infoDictionary];
				
				if ([[pluginDict objectForKey:@"BooksPluginType"] isEqual:@"Export"])
				{
					NSString * pluginName = (NSString *) [[pluginDict objectForKey:@"BooksPluginName"] copy];

					[exportPlugins setObject:plugin forKey:pluginName];
				}
			}
		}
	}
}


- (NSArray *) getDisplayStyles
{
	if (pageBuilder == nil)
		pageBuilder = [[HtmlPageBuilder alloc] init];

	NSArray * plugins = [[pageBuilder getDisplayPlugins] allKeys];
	
	return plugins;
}

- (void) setDisplayStyles: (NSArray *) list
{

}

- (void) windowWillClose: (NSNotification *) notification
{
	NSWindow * window = (NSWindow *) [notification object];

	if (window == mainWindow)
	{
		[self saveAction:self];

		[[NSApplication sharedApplication] terminate:self];
	}
	else if (window == infoWindow)
		[toolbarDelegate setGetInfoLabel:NSLocalizedString (@"Get Info", nil)];
	else if (window == coverWindow)
		[toolbarDelegate setGetCoverLabel:NSLocalizedString (@"Show Cover", nil)];
}

- (IBAction) save: (id)sender
{
    NSError *error = nil;

    if (![[self managedObjectContext] save:&error]) 
	{
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction)newSmartList:(id)sender
{
	[collectionArrayController rearrangeObjects];

	NSManagedObjectContext * context = [self managedObjectContext];
	NSManagedObjectModel * model = [self managedObjectModel];

	NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"SmartList"];

	SmartListManagedObject * sc = [[SmartListManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];
	[sc setValue:NSLocalizedString (@"New Smart List", nil) forKey:@"name"];
	
	[context lock];
	[context insertObject:sc];
	[context unlock];

	[tableViewDelegate reloadListsTable];

	NSPredicate * newPredicate = [NSPredicate predicateWithFormat:@"title CONTAINS[c] \"Book\""];
	NSString * name = @"New Smart List";

	NSArray * lists = [collectionArrayController arrangedObjects];
	
	int i = 0;
	for (i = 0; i < [lists count]; i++)
	{
		NSString * listName = [[lists objectAtIndex:i] valueForKey:@"name"];
		
		if ([[lists objectAtIndex:i] isMemberOfClass:[SmartListManagedObject class]])
		{
			SmartListManagedObject * list = [lists objectAtIndex:i];
			
			if ([newPredicate isEqual:[list getPredicate]]  && [name isEqual:listName])
				[collectionArrayController setSelectedObjects:[NSArray arrayWithObject:list]];
		}
	}
	
	[self editSmartList:sender];
}

- (IBAction) newList:(id) sender
{
	NSManagedObjectContext * context = [self managedObjectContext];
	NSManagedObjectModel * model = [self managedObjectModel];

	NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"List"];

	[context lock];
	ListManagedObject * object = [[ListManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];

	[object setValue:NSLocalizedString (@"New List", nil) forKey:@"name"];
			
	[context insertObject:object];

	[context unlock];

	[collectionArrayController setSortDescriptors:
		[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];

	[tableViewDelegate reloadListsTable];
}

- (IBAction) newBook:(id) sender
{
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] < 1)
	{

	}
	else if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];
		
		if ([list isKindOfClass:[SmartListManagedObject class]])
		{

		}
		else
		{
			NSManagedObjectContext * context = [self managedObjectContext];
			NSManagedObjectModel * model = [self managedObjectModel];

			NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"Book"];

			[context lock];
			BookManagedObject * object = [[BookManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];

			[object setValue:NSLocalizedString (@"New Book", nil) forKey:@"title"];
			
			[context insertObject:object];

			[bookArrayController addObject:object];
			[context unlock];

			[tableViewDelegate reloadBooksTable];

			if (![infoWindow isVisible])
			{
				[self getInfoWindow:nil];
			}

			[self refreshComboBoxes:nil];
		}
	}
	else
	{

	}
}

- (IBAction) removeBook:(id) sender
{
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] < 1)
	{

	}
	else if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];
		
		if ([list isKindOfClass:[SmartListManagedObject class]])
		{

		}
		else
		{
			int choice = NSRunAlertPanel (NSLocalizedString (@"Delete Selected Books?", nil), 
							NSLocalizedString (@"Are you sure you want to delete the selected books?", nil), NSLocalizedString (@"No", nil), 
							NSLocalizedString (@"Yes", nil), nil);

			if (choice == NSAlertAlternateReturn)
				[bookArrayController remove:self];
		}
	}
}

- (IBAction) removeList:(id) sender
{
	[toolbarDelegate cancelSearch];
	
	NSArray * lists = [collectionArrayController arrangedObjects];
	
	int listCount = 0;
	
	int i = 0;
	for (i = 0; i < [lists count]; i++)
	{
		NSObject * list = [lists objectAtIndex:i];
		
		if (![list isKindOfClass:[SmartListManagedObject class]])
			listCount = listCount + 1;
	}

	NSArray * objects = [collectionArrayController selectedObjects];
	ListManagedObject * list = [objects objectAtIndex:0];

	if (listCount > 1 || [list isKindOfClass:[SmartListManagedObject class]])
	{
		if ([objects count] == 1)
		{
			if ([list isKindOfClass:[SmartListManagedObject class]])
				[collectionArrayController remove:self];
			else
			{
				NSMutableSet * items = [list mutableSetValueForKey:@"items"];

				if ([items count] != 0)
				{
					int choice = NSRunAlertPanel (NSLocalizedString (@"Delete Non-Empty List?", nil), 
									NSLocalizedString (@"Are you sure you want to delete this list? It still contains items.", nil), 
									NSLocalizedString (@"No", nil), NSLocalizedString (@"Yes", nil), nil);
					
					if (choice == NSAlertAlternateReturn)
					{
						[bookArrayController setSelectedObjects:[bookArrayController arrangedObjects]];
						[bookArrayController remove:self];
					
						[collectionArrayController remove:self];
					}
				}
				else
					[collectionArrayController remove:self];
			}
		}
	}
	else
		NSRunAlertPanel (NSLocalizedString (@"Can Not Remove List", nil),  NSLocalizedString (@"The remaining list can not be removed.", nil), NSLocalizedString (@"OK", nil), nil, nil);
}

- (IBAction) editSmartList:(id) sender
{
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];
		
		if ([list isKindOfClass:[SmartListManagedObject class]])
		{
			[[smartListEditorWindow delegate] setPredicate:[((SmartListManagedObject *) list) getPredicate]];

			[[NSApplication sharedApplication] beginSheet:smartListEditorWindow modalForWindow:mainWindow
					modalDelegate:self didEndSelector:nil contextInfo:NULL];
		}
	}
}

- (IBAction) saveSmartList:(id) sender
{
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];

		[list willChangeValueForKey:@"items"];
		
		if ([list isKindOfClass:[SmartListManagedObject class]])
		{
			NSPredicate * p = [[smartListEditorWindow delegate] getPredicate];
			
			[((SmartListManagedObject *) list) setPredicate:p];
		}
		
		[list didChangeValueForKey:@"items"];

		NSIndexSet * selection = [collectionArrayController selectionIndexes];

		[collectionArrayController setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
		[collectionArrayController setSelectionIndexes:selection];
	}

	[tableViewDelegate reloadBooksTable];
	
//	[[NSApplication sharedApplication] endModalSession:session];
	[[NSApplication sharedApplication] endSheet:smartListEditorWindow];
	[smartListEditorWindow orderOut:self];
}

- (IBAction) cancelSmartList:(id) sender
{
	[[NSApplication sharedApplication] endSheet:smartListEditorWindow];
	[smartListEditorWindow orderOut:self];
}


- (NSArray *) getSelectedBooks
{
	NSArray * selectedObjects = [bookArrayController selectedObjects];
	
	if ([selectedObjects count] > 0)
		return selectedObjects;
		
	return [bookArrayController arrangedObjects];
}

- (NSArray *) getAllBooks
{
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"title != \"\""];
	
	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"Book" inManagedObjectContext:[self managedObjectContext]]];
	[fetch setPredicate:predicate];

	NSError * error = nil;
	NSArray * results = [[self managedObjectContext] executeFetchRequest:fetch error:&error];

	return [results retain];
}

- (NSArray *) getAllLists
{
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"name != \"\""];
	
	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"List" inManagedObjectContext:[self managedObjectContext]]];
	[fetch setPredicate:predicate];

	NSError * error = nil;
	NSMutableArray * results = [NSMutableArray array];
	
	NSArray * fetchedItems = [[self managedObjectContext] executeFetchRequest:fetch error:&error];

	int i = 0;
	for (i = 0; i < [fetchedItems count]; i++)
	{
		if (![[fetchedItems objectAtIndex:i] isKindOfClass:[SmartListManagedObject class]])
			[results addObject:[fetchedItems objectAtIndex:i]];
	}
	
	return [results retain];
}

- (NSArray *) getAllSmartLists
{
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"name != \"\""];
	
	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"SmartList" inManagedObjectContext:[self managedObjectContext]]];
	[fetch setPredicate:predicate];

	NSError * error = nil;
	NSArray * results = [[self managedObjectContext] executeFetchRequest:fetch error:&error];

	return [results retain];
}

- (void) selectListsTable: (id) sender
{
	[mainWindow makeFirstResponder:[tableViewDelegate getListsTable]];
}

- (void) selectBooksTable: (id) sender
{
	[mainWindow makeFirstResponder:[tableViewDelegate getBooksTable]];
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key
{
	if ([key isEqualToString:@"selectedList"])
		return YES;

	if ([key isEqualToString:@"booklists"])
		return YES;

	if ([key isEqualToString:@"selectedBooks"])
		return YES;
	
	return NO;
}

- (ListManagedObject *) getSelectedList
{
	return [[collectionArrayController selectedObjects] objectAtIndex:0];
}

- (void) setSelectedList: (ListManagedObject *) list
{
	[collectionArrayController setSelectedObjects:[NSArray arrayWithObject:list]];
}

- (NSArray *) getBooklists
{
	return [collectionArrayController arrangedObjects];
}

- (id) asCreateNewList:(NSString *) listName
{
	NSLog (@" creating as new list");
	
	NSManagedObjectContext * context = [self managedObjectContext];
	NSManagedObjectModel * model = [self managedObjectModel];

	NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"List"];

	[context lock];
	ListManagedObject * object = [[ListManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];

	if (listName != nil)
		[object setValue:listName forKey:@"name"];	
	else
		[object setValue:@"New List" forKey:@"name"];
		
	[collectionArrayController addObject:object];
	
	[context unlock];

	[tableViewDelegate reloadListsTable];

	return object;
}

- (id) asCreateNewSmartList:(NSString *) listName
{
	NSManagedObjectContext * context = [self managedObjectContext];
	NSManagedObjectModel * model = [self managedObjectModel];

	NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"SmartList"];

	[context lock];
	SmartListManagedObject * object = [[SmartListManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];

	if (listName != nil)
		[object setValue:listName forKey:@"name"];	
	else
		[object setValue:@"New Smart List" forKey:@"name"];
		
	[collectionArrayController addObject:object];
	
	[context unlock];

	[tableViewDelegate reloadListsTable];

	return object;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	openFilename = [filename retain];
	return [spotlightInterface openFile:(NSString *) filename];
}


- (IBAction) listQuickfill: (id)sender
{
	int code = NSRunInformationalAlertPanel (NSLocalizedString (@"Batch Quickfill", nil), 
				NSLocalizedString (@"Keep or overwrite existing values?", nil), 
				NSLocalizedString (@"Keep", nil), NSLocalizedString (@"Cancel", nil), 
				NSLocalizedString (@"Overwrite", nil));

	if (code == NSAlertAlternateReturn)
	{
		return;
	}

	[self save:sender];
	
	if (quickfillPlugins == nil)
		[self initQuickfillPlugins];

	NSString * pluginKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"Default Quickfill Plugin"];

	if (pluginKey == nil || [pluginKey isEqualToString:@""])
	{
		NSRunAlertPanel (NSLocalizedString (@"No Quickfill Plugin Selected", nil),  NSLocalizedString (@"No quickfill plugins have been selected. Select one in the preferences.", nil), NSLocalizedString (@"OK", nil), nil, nil);
		
		return;
	}

	NSBundle * quickfillPlugin = (NSBundle *) [quickfillPlugins objectForKey:pluginKey];
	
	NSArray * books = [bookArrayController arrangedObjects];

	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator startAnimation:self];

	NSString * message = [NSString stringWithFormat:NSLocalizedString (@"Batch quickfilling %d items...", nil), [books count], nil];

	[progressText setStringValue:message];
	
	[[NSApplication sharedApplication] beginSheet:progressView modalForWindow:mainWindow
		modalDelegate:self didEndSelector:nil contextInfo:NULL];

	quickfill = [[QuickfillPluginInterface alloc] init];

	int i = 0;
	for (i = 0; i < [books count]; i++)
	{
		[self startQuickfill];

		BOOL replace = NO;
		
		if (code == NSAlertOtherReturn)
			replace = YES;

		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:i];

		message = [NSString stringWithFormat:NSLocalizedString (@"Quickfilling item %d of %d...", nil), i + 1, [books count], nil];
		[progressText setStringValue:message];
		[progressText setNeedsDisplay:YES];
		[progressView display];

		[quickfill batchImportFromBundle:quickfillPlugin forBook:book replace:replace];
	}

	[[NSApplication sharedApplication] endSheet:progressView];
	[progressView orderOut:self];
	[progressIndicator stopAnimation:self];
}

- (IBAction) openFiles: (id) sender
{
	NSArray * books = [self getSelectedBooks];
	
	if (books != nil && [books count] == 1)
	{
		NSArray * selectedFiles = [fileArrayController selectedObjects];

		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];

		NSString * filePath = [NSString stringWithFormat:@"%@%@%@/", NSHomeDirectory (),
								@"/Library/Application Support/Books/Files/", [book getObjectIdString], nil];
	
		int i = 0;
		for (i = 0; i < [selectedFiles count]; i++)
		{
			NSDictionary * entry = [selectedFiles objectAtIndex:i];

			if (![[NSWorkspace sharedWorkspace] openFile:[entry valueForKey:@"Location"]])
				[[NSWorkspace sharedWorkspace] openFile:[filePath stringByAppendingPathComponent:[entry valueForKey:@"Location"]]];
		}
	}
}

- (IBAction) trashFiles: (id) sender
{
	NSArray * books = [self getSelectedBooks];
	
	if (books != nil && [books count] == 1)
	{
		NSArray * selectedFiles = [fileArrayController selectedObjects];

		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];

		int i = 0;
		for (i = 0; i < [selectedFiles count]; i++)
		{
			NSDictionary * entry = [selectedFiles objectAtIndex:i];
			
			[book removeFile:entry];
		}
	}
}

- (IBAction) uploadFile: (id) sender
{
//	NSString * sourceFile = [fileLocation stringValue];
	NSString * sourceName = [fileTitle stringValue];
	NSString * sourceDesc = [fileDescription stringValue];
	
	NSArray * books = [self getSelectedBooks];
	
	if (books != nil && [books count] == 1)
	{
		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];

		[book addNewFile:fullLocation title:sourceName description:sourceDesc];
		
		[fullLocation release];
		
		fullLocation = nil;
		[fileLocation setStringValue:@""];
		[fileTitle setStringValue:@""];
		[fileDescription setStringValue:@""];
		[fileIcon setImage:nil];
	}
}

- (IBAction) browseFile: (id) sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowedFileTypes:nil];
	[openPanel setAllowsMultipleSelection:NO];
	
	int result = [openPanel runModalForTypes:nil];
	
	if (result == NSOKButton)
	{
		fullLocation = [[openPanel filename] retain];
		
		[fileIcon setImage:[[NSWorkspace sharedWorkspace] iconForFile:fullLocation]];
		[fileLocation setStringValue:[fullLocation lastPathComponent]];
		[fileTitle setStringValue:[fullLocation lastPathComponent]];
	}
}

- (IBAction) viewOnline:(id) sender
{
	NSArray * books = [self getSelectedBooks];

	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSString * siteUrl = [defaults objectForKey:@"Site URL"];
	
	if (siteUrl == nil)
		siteUrl = NSLocalizedString (@"http://www.google.com/search?q=*isbn*", nil);
	
	int i = 0;
	
	if ([books count] > 10)
		NSRunAlertPanel (NSLocalizedString (@"Too Many Books Selected", nil), 
			NSLocalizedString (@"More than ten books have been selected. Only opening the first ten...", nil), 
			NSLocalizedString (@"OK", nil), nil, nil);

	for (i = 0; i < [books count] && i < 10; i++)
	{
		NSString * isbn = [[books objectAtIndex:i] valueForKey:@"isbn"];
		
		if (isbn != nil)
		{
			NSMutableString * urlString = [NSMutableString stringWithString:siteUrl];
			
			[urlString replaceOccurrencesOfString:@"*isbn*" withString:isbn options:NSCaseInsensitiveSearch 
				range:NSMakeRange (0, [urlString length])];
				
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
		}
	}
}

- (QuickfillSearchWindow *) getQuickfillResultsWindow;
{
	return quickfillResultsWindow;
}

- (IBAction) isight: (id)sender
{
	MyBarcodeScanner * iSight = [MyBarcodeScanner sharedInstance];
	[iSight setStaysOpen:NO];
	[iSight setDelegate:self];
	
	[iSight setMirrored:YES];
	
	[iSight scanForBarcodeWindow:nil];
}


- (void) gotBarcode:(NSString *)barcode 
{
	if (([barcode length] == 13 || [barcode length] == 18) && [barcode rangeOfString:@"?"].location == NSNotFound)
	{
		NSArray * selected = [self getSelectedBooks];
		
		if ([selected count] == 1)
		{
			BookManagedObject * book = (BookManagedObject *) [selected objectAtIndex:0];
			
			[book setValue:barcode forKey:@"isbn"];

			[infoWindow makeKeyAndOrderFront:nil];
			[toolbarDelegate setGetInfoLabel:NSLocalizedString (@"Hide Info", nil)];
		}
	}
}

- (IBAction) duplicateRecords:(id) sender
{
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];
		
		if (![list isKindOfClass:[SmartListManagedObject class]])
		{
			NSArray * books = [bookArrayController selectedObjects];

			NSManagedObjectContext * context = [self managedObjectContext];
			NSManagedObjectModel * model = [self managedObjectModel];
			NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"Book"];
			NSEntityDescription * fieldDesc = [[model entitiesByName] objectForKey:@"UserDefinedField"];
			
			NSArray * props = [desc properties];

			int i = 0;

			for (i = 0; i < [books count]; i++)
			{
				BookManagedObject * record = [books objectAtIndex:i];

				[context lock];
				BookManagedObject * object = [[BookManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];

				int j = 0;
				for (j = 0; j < [props count]; j++)
				{
					NSPropertyDescription * propDesc = (NSPropertyDescription *) [props objectAtIndex:j];
					NSString * name = [propDesc name];
					
					if ([propDesc isMemberOfClass:[NSAttributeDescription class]])
						[object setValue:[record valueForKey:name] forKey:name];
					else if ([name isEqualToString:@"userFields"])
					{
						NSArray * userFields = [[record valueForKey:@"userFields"] allObjects];
						
						NSMutableSet * objectFields = [object mutableSetValueForKey:@"userFields"];
						
						int k = 0;
						for (k = 0; k < [userFields count]; k++)
						{
							NSManagedObject * fieldPair = [userFields objectAtIndex:k];
							NSManagedObject * fieldObject = [[NSManagedObject alloc] initWithEntity:fieldDesc 
								insertIntoManagedObjectContext:context];

							[fieldObject setValue:[fieldPair valueForKey:@"key"] forKey:@"key"];
							[fieldObject setValue:[fieldPair valueForKey:@"value"] forKey:@"value"];
	
							[objectFields addObject:fieldObject];
						}
					}
				}

				CFUUIDRef uuid = CFUUIDCreate (kCFAllocatorDefault);
				NSString * uuidString = (NSString *) CFUUIDCreateString (kCFAllocatorDefault, uuid);
		
				[object setValue:uuidString forKey:@"id"];

				NSData * cover = [record getCoverImage];
				[object setCoverImage:[cover copyWithZone:NULL]];

				[context insertObject:object];

				[bookArrayController addObject:object];
				[context unlock];
			}
			
			[tableViewDelegate reloadBooksTable];
			
			[self refreshComboBoxes:nil];
		}
	}
}

- (IBAction) donate: (id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://books.aetherial.net/donate/"]];
}	

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
	if (aSelector == @selector(insertNewline:))
	{
		[aTextView insertNewlineIgnoringFieldEditor:nil];
		return YES;
	}
	else if (aSelector == @selector(insertTab:))
	{
		[infoWindow selectNextKeyView:nil];
		return YES;
	}	
	else if (aSelector == @selector(insertBacktab:))
	{
		[infoWindow selectPreviousKeyView:nil];
		return YES;
	}
		
	return NO;
} 

- (void) orderCoverWindowOut
{
	[coverWindow orderOut:self];
}

- (void) setDateFormatString:(NSString *) format
{
    [self willChangeValueForKey:@"now"];

	[[NSUserDefaults standardUserDefaults] setValue:format forKey:@"Custom Date Format"];
	
    [self didChangeValueForKey:@"now"];

	[tableViewDelegate updateBooksTable];
	[[datePublished cell] setFormatter:[[NSDateFormatter alloc] initWithDateFormat:format allowNaturalLanguage:YES]];
}

- (NSString *) getDateFormatString
{
	NSString * format = [[NSUserDefaults standardUserDefaults] stringForKey:@"Custom Date Format"];
	
	if (format == nil)
		format = @"%B %e, %Y";
	
	return format;
}

- (NSString *) getNow
{
	NSString * dateFormat = [self getDateFormatString];
	
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	NSDateFormatter * formatter = [[NSDateFormatter alloc] initWithDateFormat:dateFormat allowNaturalLanguage:YES];

	return [formatter stringFromDate:[NSDate date]];
}

- (void) setNow: (NSString *) now
{

}

@end
