//
//  OzyTableViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 21/05/2008.
//  Copyright Ozymandias 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CSVDataViewController;

// Make sure no value set, i.e. size = 0, corresponds to OZY_NORMAL
typedef enum OzyTableViewSize {
	OZY_NORMAL, OZY_SMALL, OZY_MINI
}OzyTableViewSize;
	
@interface OzyTableViewController : UITableViewController {
	OzyTableViewSize _size;
	NSMutableArray *_sectionIndexes;
	NSMutableArray *_sectionStarts;
	NSString *_imageName;	
}

@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, assign, getter=isEditable) BOOL editable;
@property (nonatomic, assign) BOOL reorderable;
@property (nonatomic, assign) BOOL useIndexes;
@property (nonatomic, assign) BOOL groupNumbers;
@property (nonatomic, assign) OzyTableViewSize size;
@property (nonatomic, assign) BOOL removeDisclosure;
@property (nonatomic, assign) BOOL useFixedWidth;
@property (nonatomic, strong) NSArray *sectionTitles;
@property (nonatomic, readonly) UIView *contentView;

// Default removes object from self.objects and trigs a dataLoaded
// Override for other uses
- (void) removeObjectAtIndex:(NSInteger)index;

// Default moves object in self.objects and trigs a dataLoaded
- (void) movingObjectFrom:(NSInteger)from to:(NSInteger)to;

// Only use this when not using indexes but you still want sections.
// Content should be NSNumbers, starting at "0".
- (void) setSectionStarts:(NSArray *)starts;

- (void) dataLoaded;

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
