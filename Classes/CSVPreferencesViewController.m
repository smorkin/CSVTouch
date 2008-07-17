//
//  CSVPreferencesViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 14/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "CSVPreferencesViewController.h"
#import "OzyRotatableViewController.h"

@implementation CSVPreferencesViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void) applicationDidFinishLaunching
{
	[self pushViewController:prefsSelectionController animated:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
	if( section == 0 )
		return 1;
	else
		return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"preferenceControllerCellIdentifier";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	if( indexPath.section == 0 )
	{
		cell.text = @"About";
	}
	else
	{
		if( indexPath.row == 0 )
			cell.text = @"Data";
		else if( indexPath.row == 1 )
			cell.text = @"Sorting";
		else if( indexPath.row == 2 )
			cell.text = @"Appearance";
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( indexPath.section == 0 )
		[self pushViewController:aboutController animated:YES];
	else
	{
		if( indexPath.row == 0 )
			[self pushViewController:dataPrefsController animated:YES];
		else if( indexPath.row == 1 )
			[self pushViewController:sortingPrefsController animated:YES];
		else if( indexPath.row == 2 )
			[self pushViewController:appearancePrefsController animated:YES];
	}
}
	
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if( section == 0 )
		return @"Documentation";
	else if( section == 1 )
		return @"Preferences";
	else
		return @"";
}

@end
