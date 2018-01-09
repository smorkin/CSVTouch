//
//  AutoSizingTableViewCell.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-01-06.
//

#import <UIKit/UIKit.h>

@interface AutoSizingTableViewCell : UITableViewCell
@property (nonatomic) IBOutlet UIImageView *view;
@property (nonatomic) IBOutlet UILabel *label;
@property (nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *imageWTrailingSpaceConstraint;
@end
