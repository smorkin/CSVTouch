//
//  OzyTableViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 21/05/2008.
//  Copyright Ozymandias 2008. All rights reserved.
//

#import "OzyTableViewController.h"
#import "CSVRow.h"
#import "OzymandiasAdditions.h"
#import "CSVPreferencesController.h"

#define MINI_FONT_SIZE 12
#define SMALL_FONT_SIZE 15
#define NORMAL_FONT_SIZE 20

// Custom handling of section indexes beginning with numbers
#define DIGIT_SECTION_INDEX @"0-9"

@implementation OzyTableViewController

@synthesize tableView = _tableView;
@synthesize objects = _objects;
@synthesize editable = _editable;
@synthesize useIndexes = _useIndexes;
@synthesize size = _size;
@synthesize removeDisclosure = _removeDisclosure;
@synthesize titleForSingleSection = _titleForSingleSection;

- (NSString *) comparisonCharacterForCharacter:(NSString *)character
{
	if( [character containsDigit] )
		return @"0";
	else if( (sortingMask & NSCaseInsensitiveSearch) == 0 )
		return character;
	else
		return [character lowercaseString];
}

- (NSString *) sectionTitleForCharacter:(NSString *)character
{
	if( [character containsDigit] )
		return DIGIT_SECTION_INDEX;
	else if( (sortingMask & NSCaseInsensitiveSearch) == 0 )
		return character;
	else
		return [character uppercaseString];
}

- (void) refreshIndexes
{
	if( self.useIndexes )
	{
		if( !_sectionIndexes )
			_sectionIndexes = [[NSMutableArray alloc] init];
		else
			[_sectionIndexes removeAllObjects];
		if( !_sectionStarts )
			_sectionStarts = [[NSMutableArray alloc] init];
		else
			[_sectionStarts removeAllObjects];
		NSUInteger objectCount = [self.objects count];
		NSString *latestFirstLetter = nil;
		NSString *currentFirstLetter;
		for( NSUInteger i = 0 ; i < objectCount ; i++)
		{
			NSString *shortDescription = [(CSVRow *)[self.objects objectAtIndex:i] shortDescription];
			if( [shortDescription length] == 0 )
				continue;
			
			// For performance reasons, we compare using isEqualToString: before we
			// do the possible transformation to comparison character 
			currentFirstLetter = [shortDescription substringToIndex:1];
			if(!latestFirstLetter ||
			   (![currentFirstLetter isEqualToString:latestFirstLetter] && 
				![[self comparisonCharacterForCharacter:currentFirstLetter] isEqualToString:
				  [self comparisonCharacterForCharacter:latestFirstLetter]] ))
			{
				[_sectionStarts addObject:[NSNumber numberWithInt:i]];
				[_sectionIndexes addObject:[self sectionTitleForCharacter:currentFirstLetter]];
				latestFirstLetter = currentFirstLetter;
			}				
			else if(![currentFirstLetter isEqualToString:latestFirstLetter] && 
					![[self comparisonCharacterForCharacter:currentFirstLetter] isEqualToString:
					  [self comparisonCharacterForCharacter:latestFirstLetter]] )
			{
				[_sectionStarts addObject:[NSNumber numberWithInt:i]];
				[_sectionIndexes addObject:[self sectionTitleForCharacter:currentFirstLetter]];
				latestFirstLetter = currentFirstLetter;
			}
		}
	}
}

- (void) setObjects:(NSMutableArray *)objects
{
	if( objects != self.objects )
	{
		[_objects autorelease];
		_objects = [objects retain];
	}
	[self refreshIndexes];
}

- (void) setSize:(OzyTableViewSize)size
{
	if( size != self.size )
	{
		_size = size;
		switch (size )
		{
			case OZY_MINI:
				self.tableView.rowHeight = 18;
				self.tableView.sectionHeaderHeight = 24;
				break;
			case OZY_SMALL:
				self.tableView.rowHeight = 27;
				self.tableView.sectionHeaderHeight = 24;
				break;
			case OZY_NORMAL:
			default:
				self.tableView.rowHeight = 44;
				self.tableView.sectionHeaderHeight = 24;
				break;
		}
		[self.tableView reloadData];
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( editingStyle == UITableViewCellEditingStyleDelete )
	{
		NSInteger index = indexPath.row;
		id objectToRemove = [[self.objects objectAtIndex:index] retain];
		[self.objects removeObjectAtIndex:index];
		self.navigationItem.rightBarButtonItem.enabled = TRUE;
		[self.tableView reloadData];
		[[NSNotificationCenter defaultCenter] postNotificationName:OzyContentChangedInTableView 
															object:self
														  userInfo:[NSDictionary dictionaryWithObject:objectToRemove
																							   forKey:OzyRemovedTableViewObject]];
		[objectToRemove release];
	}
}

- (NSUInteger) indexForObjectAtIndexPath:(NSIndexPath *)indexPath
{
	if( [_sectionStarts count] > 0 )
	{
		if( indexPath.section < [_sectionStarts count] )
			return [[_sectionStarts objectAtIndex:indexPath.section] intValue] + indexPath.row;
		else
			return NSNotFound;
	}
	else
	{
		return indexPath.row;
	}
}

- (BOOL) itemExistsAtIndexPath:(NSIndexPath *)indexPath
{
	if( [_sectionStarts count] > 0 )
	{
		if( indexPath.section == [_sectionStarts count] - 1 )
			return [[_sectionStarts objectAtIndex:indexPath.section] intValue] + indexPath.row < [self.objects count];
		else if( indexPath.section < [_sectionStarts count] - 1 )
			return [[_sectionStarts objectAtIndex:indexPath.section] intValue] + indexPath.row < 
			[[_sectionStarts objectAtIndex:indexPath.section + 1] intValue];
		else
			return NO;
	}
	else if( indexPath.section != 0 )
	{
		return NO;
	}
	else
	{
		return indexPath.row < [self.objects count];
	}
}	

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if( [_sectionStarts count] > 0 )
	{
		if( section == [_sectionStarts count] - 1 )
			return [self.objects count] - [[_sectionStarts objectAtIndex:section] intValue];
		else
			return [[_sectionStarts objectAtIndex:section+1] intValue] - [[_sectionStarts objectAtIndex:section] intValue];
	}
	else
	{
		return [self.objects count];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if( [_sectionStarts count] > 0 )
	{
		return [_sectionStarts count];
	}
	else
	{
		return 1;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if( [_sectionIndexes count] > 0 )
	{
		return [_sectionIndexes objectAtIndex:section];
	}
	else
	{
		return (self.titleForSingleSection ? self.titleForSingleSection : @"");
	}
	
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	if( [_sectionIndexes count] > 0 )
	{
		return _sectionIndexes;
	}
	else
	{
		return nil;
	}	
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	if( [_sectionIndexes count] > 0 )
	{
		return [_sectionIndexes indexOfObject:title];
	}
	else
	{
	return 0;
	}
}

- (UITableViewCell *) tableViewCell
{
	static NSString *miniIdentifier = @"miniIdentifier";
	static NSString *smallIdentifier = @"smallIdentifier";
	static NSString *normalIdentifier = @"normalIdentifier";
	NSString *cellIdentifier;
	CGFloat fontSize;
	
	switch (self.size )
	{
		case OZY_MINI:
			cellIdentifier = miniIdentifier;
			fontSize = MINI_FONT_SIZE;
			break;
		case OZY_SMALL:
			cellIdentifier = smallIdentifier;
			fontSize = SMALL_FONT_SIZE;
			break;
		case OZY_NORMAL:
		default:
			cellIdentifier = normalIdentifier;
			fontSize = NORMAL_FONT_SIZE;
			break;
	}
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	// Setup the cell if not already setup
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
	}
	
	[cell setFont:[[cell font] fontWithSize:fontSize]];
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	UITableViewCell *cell = [self tableViewCell];
	id item;
	
	if( [_sectionStarts count] > 0 )
		item = [self.objects objectAtIndex:[[_sectionStarts objectAtIndex:indexPath.section] intValue] + indexPath.row];
	else
		item = [self.objects objectAtIndex:indexPath.row];
	if( [item conformsToProtocol:@protocol(OzyTableViewObject)] )
		cell.text = [(<OzyTableViewObject>)item tableViewDescription];
	else
		cell.text = [item description];
	if( self.removeDisclosure )
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else
	{
		cell.accessoryType = (self.useIndexes ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator);
	}
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return self.editable;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return self.editable;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{	
	NSInteger fromIndex = fromIndexPath.row;
	NSInteger toIndex = toIndexPath.row;
	if( [_sectionStarts count] > 0 )
	{
		fromIndex = [[_sectionStarts objectAtIndex:fromIndexPath.section] intValue] + fromIndexPath.row;
		toIndex = [[_sectionStarts objectAtIndex:toIndexPath.section] intValue] + toIndexPath.row;
	}
	else
	{
		fromIndex = fromIndexPath.row;
		toIndex = toIndexPath.row;
	}
	id item = [[self.objects objectAtIndex:fromIndex] retain];
	[self.objects removeObjectAtIndex:fromIndex];
	[self.objects insertObject:item atIndex:toIndex];
	self.navigationItem.rightBarButtonItem.enabled = TRUE;
	[item release];
	[[NSNotificationCenter defaultCenter] postNotificationName:OzyContentChangedInTableView object:self];
}

- (void)dealloc {
	self.objects = nil;
	[_sectionStarts release];
	[_sectionIndexes release];
	[super dealloc];
}

- (void) dataLoaded
{
	[self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if( [[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(allowRotation)] )
		return [(id <OzymandiasApplicationDelegate>)[[UIApplication sharedApplication] delegate] allowRotation];
	else
		return YES;
}

// Not used right now
+ (UIView *) headerViewForSize:(OzyTableViewSize)size
{
	static UILabel *miniView = nil;
	static UILabel *smallView = nil;
	static UILabel *normalView = nil;
	
	if( !miniView )
	{
		miniView = [[UILabel alloc] init];
		miniView.font = [miniView.font fontWithSize:MINI_FONT_SIZE];
		miniView.textColor = [UIColor whiteColor];
		smallView = [[UILabel alloc] init];
		smallView.font = [smallView.font fontWithSize:SMALL_FONT_SIZE];
		smallView.textColor = [UIColor whiteColor];
		normalView = [[UILabel alloc] init];
		normalView.font = [normalView.font fontWithSize:NORMAL_FONT_SIZE];
		normalView.textColor = [UIColor whiteColor];
	}
	switch (size)
	{
		case MINI_FONT_SIZE:
			return miniView;
		case SMALL_FONT_SIZE:
			return smallView;
		case NORMAL_FONT_SIZE:
		default:
			return normalView;
	}
}

@end

