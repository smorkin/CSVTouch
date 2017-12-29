//
//  CSVDataViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 23/05/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "CSVDataViewController.h"
#import "CSV_TouchAppDelegate.h"

@implementation CSVDataViewController

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
    [CSV_TouchAppDelegate sharedInstance].dataController = self;
    self.delegate = [CSV_TouchAppDelegate sharedInstance];
	return self;
}

- (void) selectedItemAtIndexPath:(NSIndexPath *)indexPath
{
//    BOOL resetSearch = NO;
//    if( searchInputInProgress )
//    {
//        [self searchFinish];
//        if( [CSVPreferencesController clearSearchWhenQuickSelecting] )
//            resetSearch = YES;
//    }
//
//    [self selectDetailsForRow:[self.itemController indexForObjectAtIndexPath:indexPath]];
//    [self pushViewController:[self currentDetailsController] animated:YES];
//
//    if( resetSearch )
//    {
//        self.searchBar.text = @"";
//        CSVRow *selectedItem = [[self.itemController objects] objectAtIndex:[self.itemController indexForObjectAtIndexPath:indexPath]];
//        NSUInteger newPosition = [[[self currentFile] itemsWithResetShortdescriptions:NO] indexOfObject:selectedItem];
//        if( newPosition != NSNotFound )
//        {
//            NSIndexPath *newPath = [self.itemController indexPathForObjectAtIndex:newPosition];
//            if( newPath )
//            {
//                [self.itemController.tableView selectRowAtIndexPath:newPath
//                                                           animated:NO
//                                                     scrollPosition:UITableViewScrollPositionTop];
//                [self updateBadgeValueUsingItem:[[self currentDetailsController] navigationItem]
//                                           push:YES];
//            }
//        }
//    }
    
}

@end
