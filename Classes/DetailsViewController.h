//
//  DetailsViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-29.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "CSVRow.h"

@interface DetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UITableView *fancyView;
@property (nonatomic, strong) UITextView *simpleView;

@property (nonatomic, strong) CSVRow *row;

@end
