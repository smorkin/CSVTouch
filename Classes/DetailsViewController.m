//
//  DetailsViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-29.
//

#import "DetailsViewController.h"
#import "OzymandiasAdditions.h"
#import "CSVPreferencesController.h"
#import "CSV_TouchAppDelegate.h"

@interface DetailsViewController ()
@property (nonatomic, strong) UIBarButtonItem *viewSelection;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UITableView *fancyView;
@property (nonatomic, strong) UITextView *simpleView;
@end

@interface DetailsViewController (Fancy) <UITableViewDataSource, UITableViewDelegate>
@end

@interface DetailsViewController (Web) <WKNavigationDelegate>
- (void) delayedHtmlClick:(NSURL *)URL;
- (void) updateWebViewContent;
@end

@implementation DetailsViewController

- (void) setup
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.webView = [[WKWebView alloc] init];
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor whiteColor];
    self.webView.navigationDelegate = self;
    self.simpleView = [[UITextView alloc] init];
    self.fancyView = [[UITableView alloc] init];
    [self.fancyView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DetailsCell"];
    self.fancyView.dataSource = self;
    self.fancyView.delegate = self;
    self.fancyView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    UISegmentedControl *c = [[UISegmentedControl alloc] initWithItems: @[@"1", @"2", @"3"]];
    [c addTarget:self
          action:@selector(viewSelectionChanged)
forControlEvents:UIControlEventValueChanged];
    self.viewSelection = [[UIBarButtonItem alloc] initWithCustomView:c];
    self.view = self.simpleView;
}

- (void) awakeFromNib
{
    [self setup];
    [super awakeFromNib];
}
- (void) viewWillAppear:(BOOL)animated
{
    self.simpleView.text = [self.row longDescriptionWithHiddenValues:NO];
    self.navigationController.toolbarHidden = YES;
    NSInteger viewToSelect = [CSVPreferencesController selectedDetailsView];
    if( viewToSelect >= [(UISegmentedControl *)self.viewSelection.customView numberOfSegments] ){
        viewToSelect = 0;
    }
    [(UISegmentedControl *)self.viewSelection.customView setSelectedSegmentIndex:viewToSelect];
    [self viewSelectionChanged];
    self.navigationItem.rightBarButtonItem = self.viewSelection;
    [super viewWillAppear:animated];
}

- (void) viewSelectionChanged
{
    NSInteger viewToSelect = [(UISegmentedControl *)self.viewSelection.customView selectedSegmentIndex];
    if( viewToSelect == 0 ){
        self.view = self.webView;
        [self updateWebViewContent];
    }
    else if( viewToSelect == 1 ){
        self.view = self.fancyView;
    }
    else if( viewToSelect == 2 ){
        self.view = self.simpleView;
    }
    [CSVPreferencesController setSelectedDetailsView:viewToSelect];
}

- (NSArray *) objects
{
    return [self.row longDescriptionInArrayWithHiddenValues:NO];
}

@end

@implementation DetailsViewController (Fancy)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self objects] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.fancyView dequeueReusableCellWithIdentifier:@"DetailsCell"];
    cell.textLabel.text = [[self objects] objectAtIndex:indexPath.row];
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
        NSArray *words = [[[self objects] objectAtIndex:indexPath.row]
                          componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        for(NSString *word in words)
        {
            if( [word containsURL] )
            {
                [self delayedHtmlClick:[NSURL URLWithString:word]];
            }
            else if( [word containsMailAddress] )
            {
                [self delayedHtmlClick:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", word]]];
            }
        }
}

@end

@implementation DetailsViewController (Web)

+ (NSString *) sandboxedFileURLFromLocalURL:(NSString *) localURL
{
    // We assume that the localURL has already been checked for a true local file URL
    NSArray *tmpArray = [localURL componentsSeparatedByString:@"file://"];
    if( [tmpArray count] == 2 )
    {
        NSMutableString *s = [NSMutableString string];
        [s appendString:@"file://"];
        [s appendString:[[CSV_TouchAppDelegate localMediaDocumentsPath] stringByAppendingPathComponent:[tmpArray objectAtIndex:1]]];
        return s;
    }
    else
        return localURL;
}

- (void) delayedHtmlClick:(NSURL *)URL
{
    if( [CSVPreferencesController confirmLink] )
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Leave %@",
                                                                                ([CSVPreferencesController restrictedDataVersionRunning] ? @"CSV Lite" : @"CSV Touch")]
                                                                       message:[NSString stringWithFormat:@"Continue opening %@?", [URL absoluteString]]
                                                                 okButtonTitle:@"OK"
                                                                     okHandler:^(UIAlertAction *action) {
                                                                         [[UIApplication sharedApplication] openURL:URL
                                                                                                            options:[NSDictionary dictionary]
                                                                                                  completionHandler:nil];
                                                                     }
                                                             cancelButtonTitle:@"Cancel"
                                                                 cancelHandler:nil];
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
    }
    else
    {
        [[UIApplication sharedApplication] openURL:URL
                                           options:[NSDictionary dictionary]
                                 completionHandler:nil];
    }
}

- (void) updateWebViewContent
{
    [self.webView stopLoading];
    
    BOOL useTable = [CSVPreferencesController alignHtml];
    NSError *error;
    NSString *cssString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"seaglass" ofType:@"css"]
                                                usedEncoding:nil
                                                       error:&error];
    
    NSMutableString *s = [NSMutableString string];
    [s appendString:@"<html><head><title>Details</title>"];
    [s appendString:@"<STYLE type=\"text/css\">"];
    [s appendString:cssString];
    [s appendString:@"</STYLE>"];
    
    [s replaceOccurrencesOfString:@"normal 36px verdana"
                       withString:@"normal 24px verdana"
                          options:0
                            range:NSMakeRange(0, [s length])];
    [s appendString:@"</head><body>"];
    if( useTable )
        [s appendString:@"<table width=\"100%\">"];
    else
        [s appendFormat:@"<p><font size=\"+5\">"];
    NSMutableString *data = [NSMutableString string];
    NSArray *columnsAndValues = [self.row columnsAndValues];
    NSInteger row = 1;
    for( NSDictionary *d in columnsAndValues )
    {
        // Are we done already?
        if(row > [self.row.fileParser.shownColumnIndexes count] &&
           ![CSVPreferencesController showDeletedColumns])
            break;
        
        if( useTable )
        {
            if(row != 1 && // In case someone has a file where no column is important...
               row-1 == [self.row.fileParser.shownColumnIndexes count] &&
               [self.row.fileParser.shownColumnIndexes count] != [columnsAndValues count] )
            {
                [data appendString:@"<tr class=\"rowstep\"><th><b>-</b><td>"];
                [data appendString:@"<tr class=\"rowstep\"><th><b>-</b><td>"];
            }
            
            [data appendFormat:@"<tr%@><th valign=\"top\"><b>%@</b>",
             ((row % 2) == 1 ? @" class=\"odd\"" : @""),
             [d objectForKey:COLUMN_KEY]];
            if( [[d objectForKey:VALUE_KEY] containsImageURL] && [CSVPreferencesController showInlineImages] )
                [data appendFormat:@"<td><img src=\"%@\">", [d objectForKey:VALUE_KEY]];
            else if( [[d objectForKey:VALUE_KEY] containsLocalImageURL] && [CSVPreferencesController showInlineImages] )
                [data appendFormat:@"<td><img src=\"%@\"></img>", [DetailsViewController sandboxedFileURLFromLocalURL:[d objectForKey:VALUE_KEY]]];
            else if( [[d objectForKey:VALUE_KEY] containsLocalMovieURL] && [CSVPreferencesController showInlineImages] )
                [data appendFormat:@"<td><video src=\"%@\" controls x-webkit-airplay=\"allow\"></video>", [DetailsViewController sandboxedFileURLFromLocalURL:[d objectForKey:VALUE_KEY]]];
            else if( [[d objectForKey:VALUE_KEY] containsURL] )
                [data appendFormat:@"<td><a href=\"%@\">%@</a>", [d objectForKey:VALUE_KEY], [d objectForKey:VALUE_KEY]];
            else if( [[d objectForKey:VALUE_KEY] containsMailAddress] )
                [data appendFormat:@"<td><a href=\"mailto:%@\">%@</a>", [d objectForKey:VALUE_KEY], [d objectForKey:VALUE_KEY]];
            else
                [data appendFormat:@"<td>%@", [d objectForKey:VALUE_KEY]];
        }
        else
        {
            [data appendFormat:@"<b>%@</b>: ", [d objectForKey:COLUMN_KEY]];
            if( [[d objectForKey:VALUE_KEY] containsImageURL] && [CSVPreferencesController showInlineImages] )
                [data appendFormat:@"<br><img src=\"%@\"></img><br>", [d objectForKey:VALUE_KEY]];
            else if( [[d objectForKey:VALUE_KEY] containsLocalImageURL] && [CSVPreferencesController showInlineImages] )
                [data appendFormat:@"<br><img src=\"%@\"></img><br>", [DetailsViewController sandboxedFileURLFromLocalURL:[d objectForKey:VALUE_KEY]]];
            else if( [[d objectForKey:VALUE_KEY] containsLocalMovieURL] && [CSVPreferencesController showInlineImages] )
                [data appendFormat:@"<br><video src=\"%@\" controls x-webkit-airplay=\"allow\"></video><br>", [DetailsViewController sandboxedFileURLFromLocalURL:[d objectForKey:VALUE_KEY]]];
            else if( [[d objectForKey:VALUE_KEY] containsURL] )
                [data appendFormat:@"<a href=\"%@\">%@</a><br>", [d objectForKey:VALUE_KEY], [d objectForKey:VALUE_KEY]];
            else if( [[d objectForKey:VALUE_KEY] containsMailAddress] )
                [data appendFormat:@"<a href=\"mailto:%@\">%@</a><br>", [d objectForKey:VALUE_KEY], [d objectForKey:VALUE_KEY]];
            else
                [data appendFormat:@"%@<br>", [d objectForKey:VALUE_KEY]];
        }
        row++;
    }
    [data replaceOccurrencesOfString:@"\n"
                          withString:@"<br>"
                             options:0
                               range:NSMakeRange(0, [data length])];
    [s appendString:data];
    if( useTable )
        [s appendFormat:@"</table>"];
    else
        [s appendFormat:@"</p>"];
    [s appendFormat:@"</body></html>"];
    [self.webView loadHTMLString:s baseURL:nil];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if( navigationAction.navigationType == WKNavigationTypeLinkActivated)
    {
        decisionHandler(WKNavigationActionPolicyCancel);
        [self delayedHtmlClick:navigationAction.request.URL];
    }
    else
    {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}
@end
