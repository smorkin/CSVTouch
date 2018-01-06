//
//  ParseErrorViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import <UIKit/UIKit.h>
#import "CSVFileParser.h"

@interface ParseErrorViewController : UIViewController

@property IBOutlet UITextView *textView;
@property (nonatomic, strong) NSString *errorText;

@end
