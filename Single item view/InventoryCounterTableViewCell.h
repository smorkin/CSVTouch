//
//  InventoryCounterTableViewCell.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2019-03-15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface InventoryCounterTableViewCell : UITableViewCell
@property IBOutlet UITextField *text;

- (IBAction)increase:(id)sender;
- (IBAction)decrease:(id)sender;

@end

NS_ASSUME_NONNULL_END
