//
//  OzyTableViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 21/05/2008.
//  Copyright Ozymandias 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CSVDataViewController;

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
	BOOL _reorderable;
	BOOL _useIndexes;
	BOOL _groupNumbers;
	BOOL _removeDisclosure;
	BOOL _useFixedWidth;
	OzyTableViewSize _size;
	NSMutableArray *_sectionIndexes;
	NSMutableArray *_sectionStarts;
	NSArray *_sectionTitles;
	NSString *_imageName;
	id _viewDelegate;
	
	// Ads
	IBOutlet UIView *_contentView;		
}

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, retain) NSMutableArray *objects;
@property (nonatomic, assign, getter=isEditable) BOOL editable;
@property (nonatomic, assign) BOOL reorderable;
@property (nonatomic, assign) BOOL useIndexes;
@property (nonatomic, assign) BOOL groupNumbers;
@property (nonatomic, assign) OzyTableViewSize size;
@property (nonatomic, assign) BOOL removeDisclosure;
@property (nonatomic, assign) BOOL useFixedWidth;
@property (nonatomic, retain) NSArray *sectionTitles;
//@property (nonatomic, retain) NSString *imageName;
@property (nonatomic, assign) id viewDelegate;
@property (nonatomic, readonly) UIView *contentView;


// Only use this when not using indexes but you still want sections.
// Content should be NSNumbers, starting at "0".
- (void) setSectionStarts:(NSArray *)starts;

- (void) dataLoaded;

+ (UIView *) headerViewForSize:(OzyTableViewSize)size;

- (NSUInteger) indexForObjectAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *) indexPathForObjectAtIndex:(NSUInteger)index;
- (BOOL) itemExistsAtIndexPath:(NSIndexPath *)indexPath;

// Note that setObjects does this automatically, so only call if you have manipulated objects
// some other way using OzyTableViewCOntroller.objects method.
- (void) refreshIndexes;

@end

// For objects shown in an UITableView in an OzyTableViewController, if the object wants to show something
// different from [obj description]
@protocol OzyTableViewObject
- (NSString *) tableViewDescription;
- (NSString *) imageName;
- (NSString *) emptyImageName; // In case no image name has been set but you want a default image
@end