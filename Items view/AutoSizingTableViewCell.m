//
//  AutoSizingTableViewCell.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-01-06.
//

#import "AutoSizingTableViewCell.h"

@implementation AutoSizingTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.separatorInset = UIEdgeInsetsZero; // We want the line between rows to include image part of cell
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
