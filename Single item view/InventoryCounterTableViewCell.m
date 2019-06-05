//
//  InventoryCounterTableViewCell.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2019-03-15.
//

#import "InventoryCounterTableViewCell.h"

@implementation InventoryCounterTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)increase:(id)sender
{
    self.text.text = @"Increase";
}

- (IBAction)decrease:(id)sender
{
    self.text.text = @"Decrease";
}

@end
