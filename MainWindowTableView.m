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


#import "MainWindowTableView.h"
#import "BooksAppDelegate.h"

@implementation MainWindowTableView

- (void) keyDown: (NSEvent *) event
{
	unichar arrow = [[event characters] characterAtIndex:0];
	
	if (arrow == NSLeftArrowFunctionKey)
		[((BooksAppDelegate *) [NSApp delegate]) selectListsTable:self];
	else if (arrow == NSRightArrowFunctionKey)
		[((BooksAppDelegate *) [NSApp delegate]) selectBooksTable:self];
	else if (arrow == 13 || arrow == 3)
		[((BooksAppDelegate *) [NSApp delegate]) getInfoWindow:self];
	// else if (arrow == ' ')
	//	[((BooksAppDelegate *) [[NSApplication sharedApplication] delegate]) pageContent:self];
	else
		[super keyDown:event];
}

- (NSMenu *) menuForEvent:(NSEvent *)theEvent
{
	if (self == [[self delegate] getListsTable])
	{
		// Code from http://lists.apple.com/archives/Cocoa-dev/2003/Aug/msg01442.html
	
		int row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];

		if (row != -1) 
			[self selectRow:row byExtendingSelection: NO];

		NSMenu * menu = [[NSMenu alloc] init];
		[menu addItemWithTitle:NSLocalizedString (@"Rename List", nil) action:NSSelectorFromString(@"renameList:") keyEquivalent:@""];
		[menu addItemWithTitle:NSLocalizedString (@"Delete List", nil) action:NSSelectorFromString(@"deleteList:") keyEquivalent:@""];

		return menu;
	}
	else if (self == [[self delegate] getBooksTable])
	{
		int row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];

		if (row != -1) 
			[self selectRow:row byExtendingSelection: NO];

		NSMenu * menu = [[NSMenu alloc] init];
		[menu addItemWithTitle:NSLocalizedString (@"Delete Book", nil) action:NSSelectorFromString(@"deleteBook:") keyEquivalent:@""];

		return menu;
	}

	return nil;
}

- (IBAction) renameList: (id) sender
{
	if (self == [[self delegate] getListsTable])
	{
		int row = [self selectedRow];

		if (row != -1) 
			[self editColumn:1 row:row withEvent:nil select:YES];
	}
}

- (IBAction) deleteList: (id) sender
{
	if (self == [[self delegate] getListsTable])
		[((BooksAppDelegate *) [NSApp delegate]) removeList:(id) sender];
}

- (IBAction) deleteBook: (id) sender
{
	if (self == [[self delegate] getBooksTable])
		[((BooksAppDelegate *) [NSApp delegate]) removeBook:(id) sender];
}

@end
