//
//  OzyTableViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 21/05/2008.
//  Copyright Ozymandias 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CSVDataViewController, OzyTableViewController;

// Notice posted when something is changed in an OzyTableViewcontroller's tableview.
// If an object is removed, it can be found in userInfo using the key below.
#define OzyContentChangedInTableView @"OzyContentChangedInTableView"
#define OzyRemovedTableViewObject @"OzyRemovedTableViewObject"

// Make sure no value set, i.e. size = 0, corresponds to OZY_NORMAL
typedef enum OzyTableViewSize {
	OZY_NORMAL, OZY_SMALL, OZY_MINI
}OzyTableViewSize;
	
@interface OzyTableViewController : UIViewController <UITableViewDataSource> {
	IBOutlet UITableView *_tableView;
	NSMutableArray *_objects;
	BOOL _editable;
	BOOL _useIndexes;
	OzyTableViewSize _size;
	NSMutableArray *_sectionIndexes;
	NSMutableArray *_sectionStarts;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSMutableArray *objects;
@property (nonatomic, assign, getter=isEditable) BOOL editable;
@property (nonatomic, assign) BOOL useIndexes;
@property (nonatomic, assign) OzyTableViewSize size;

- (void) dataLoaded;

+ (UIView *) headerViewForSize:(OzyTableViewSize)size;

- (NSIndexPath *) indexPathForObjectAtIndex:(NSUInteger)index;
- (NSUInteger) indexForObjectAtIndexPath:(NSIndexPath *)indexPath;

// Note that setObjects does this automatically, so only call if you have manipulated objects
// some other way using OzyTableViewCOntroller.objects method.
- (void) refreshIndexes;

@end

// For objects shown in an UITableView in an OzyTableViewController, if the object wants to show something
// different from [obj description]
@protocol OzyTableViewObject
- (NSString *) tableViewDescription;
@end