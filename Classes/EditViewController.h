//
//  EditViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-17.
//

#import "OzyTableViewController.h"
#import "CSVRow.h"

@interface EditViewController : UITableViewController

- (void) setFile:(CSVFileParser *)file;

@end
