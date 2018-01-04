//
//  ParseErrorViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "OzyTextViewController.h"
#import "CSVFileParser.h"

@interface ParseErrorViewController : OzyTextViewController

@property (nonatomic, strong) NSString *errorText;

@end
