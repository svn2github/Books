#import "BooksTextFieldDelegate.h"
#import "BooksAppDelegate.h"

@implementation BooksTextFieldDelegate

- (BooksTextFieldDelegate *) init
{
	self = [super init];
	refresh = true;
	
	genreSet = [[NSMutableSet alloc] init];
	authorSet = [[NSMutableSet alloc] init];
	illustratorSet = [[NSMutableSet alloc] init];
	editorSet = [[NSMutableSet alloc] init];
	translatorSet = [[NSMutableSet alloc] init];
	keywordSet = [[NSMutableSet alloc] init];
	publisherSet = [[NSMutableSet alloc] init];

	tokenList = [[NSArray alloc] initWithObjects:genreSet, authorSet, editorSet, illustratorSet, translatorSet, keywordSet, publisherSet, nil];
	fieldList = [[NSArray alloc] initWithObjects:@"genre", @"authors", @"editors", @"illustrators", @"translators", @"keywords", @"publisher", nil];
	
	return self;
}

- (void) updateTokens
{
	refresh = true;
}

- (void) update
{
	int i = 0;
	for (i = 0; i < [tokenList count]; i++)
		[((NSMutableSet *) [tokenList objectAtIndex:i]) removeAllObjects];
		
	[genreSet addObject:NSLocalizedString (@"Biography", nil)];
	[genreSet addObject:NSLocalizedString (@"Fantasy", nil)];
	[genreSet addObject:NSLocalizedString (@"Fairy Tales", nil)];
	[genreSet addObject:NSLocalizedString (@"Historical Fiction", nil)];
	[genreSet addObject:NSLocalizedString (@"Myths & Legends", nil)];
	[genreSet addObject:NSLocalizedString (@"Poetry", nil)];
	[genreSet addObject:NSLocalizedString (@"Science Fiction", nil)];
	[genreSet addObject:NSLocalizedString (@"Folk Tales", nil)];
	[genreSet addObject:NSLocalizedString (@"Mystery", nil)];
	[genreSet addObject:NSLocalizedString (@"Non-Fiction", nil)];
	[genreSet addObject:NSLocalizedString (@"Realistic Fiction", nil)];
	[genreSet addObject:NSLocalizedString (@"Short Stories", nil)];

	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"Book" inManagedObjectContext:[((BooksAppDelegate *) [NSApp delegate]) managedObjectContext]]];

	NSError * error = nil;
	NSArray * books = [[((BooksAppDelegate *) [NSApp delegate]) managedObjectContext] executeFetchRequest:fetch error:&error];
	
	for (i = 0; i < [books count]; i++)
	{
		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:i];
	
		int j = 0;
		for (j = 0; j < [fieldList count] && j < [tokenList count]; j++)
		{
			NSObject * value = [book valueForKey:[fieldList objectAtIndex:j]];
			
			if (value != nil)
				[[tokenList objectAtIndex:j] addObject:value];
		}
	}

	[fetch release];
	
	refresh = false;
}

- (id) comboBox: (NSComboBox *) box objectValueForItemAtIndex:(int) index
{
	if (refresh)
		[self update];
	
	NSArray * items = [NSArray array];
	
	if (box == genre)
		items = [genreSet allObjects];
	else if (box == authors)
		items = [authorSet allObjects];
	else if (box == illustrators)
		items = [illustratorSet allObjects];
	else if (box == editors)
		items = [editorSet allObjects];
	else if (box == translators)
		items = [translatorSet allObjects];
	else if (box == keywords)
		items = [keywordSet allObjects];
	else if (box == publisher)
		items = [publisherSet allObjects];
		  
	items = [items sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	return [items objectAtIndex:index];
}

- (int)numberOfItemsInComboBox:(NSComboBox *) box
{
	if (refresh)
		[self update];

	NSArray * items = [NSArray array];

	if (box == genre)
		items = [genreSet allObjects];
	else if (box == authors)
		items = [authorSet allObjects];
	else if (box == illustrators)
		items = [illustratorSet allObjects];
	else if (box == editors)
		items = [editorSet allObjects];
	else if (box == translators)
		items = [translatorSet allObjects];
	else if (box == keywords)
		items = [keywordSet allObjects];
	else if (box == publisher)
		items = [publisherSet allObjects];

	return [items count];
}

@end
