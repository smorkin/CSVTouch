//
//  FilesViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "OzyTableViewController.h"
#import "CSVFileParser.h"

@interface FilesViewController : OzyTableViewController

+ (instancetype) sharedInstance;

- (IBAction) addNewFile;

@end
