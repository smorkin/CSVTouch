//
//  DetailsViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-29.
//

#import "DetailsViewController.h"
#import "DetailsPagesController.h"
#import "OzymandiasAdditions.h"
#import "CSVPreferencesController.h"
#import "CSV_TouchAppDelegate.h"
#import "CSSProvider.h"

@interface DetailsViewController ()
@property (nonatomic, strong) WKWebView *webView;
@property CGFloat originalPointsWhenPinchStarted;
@property BOOL imageShown;
@property UIPinchGestureRecognizer *pinchGesture;
@end

@interface DetailsViewController (Web) <WKNavigationDelegate, UIGestureRecognizerDelegate>
- (void) delayedHtmlClick:(NSURL *)URL;
- (void) updateContent;
@end

@interface DetailsViewController (LocalFileAccess) <WKURLSchemeHandler>
@end

@implementation DetailsViewController (LocalFileAccess)

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask
{
    NSURL* url = urlSchemeTask.request.URL;
    NSData* data = [NSData dataWithContentsOfFile: url.path];
    NSURLResponse* response = [[NSURLResponse alloc] initWithURL:url MIMEType:nil expectedContentLength:[data length] textEncodingName:nil];

    [urlSchemeTask didReceiveResponse:response];
    [urlSchemeTask didReceiveData:data];
    [urlSchemeTask didFinish];
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask
{}

@end

@implementation DetailsViewController

- (void) setupWebView
{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    [config  setURLSchemeHandler:self forURLScheme:@"localfile"];
    config.allowsInlineMediaPlayback = TRUE;
    config.dataDetectorTypes = WKDataDetectorTypeAll;
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    self.webView.opaque = NO;
    self.webView.backgroundColor = [CSVPreferencesController systemBackgroundColor];
    self.webView.navigationDelegate = self;
    [self.webView addGestureRecognizer:self.pinchGesture];
    self.webView.allowsLinkPreview = YES;
    self.view = self.webView;

}

- (void) setup
{
    self.hasLoadedData = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                  action:@selector(pinch:)];
    self.pinchGesture.delegate = self;
    [self setupWebView];
}

- (void) awakeFromNib
{
    [self setup];
    [super awakeFromNib];
}

- (instancetype) init
{
    self = [super init];
    [self setup];
    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
    [self refreshData:NO];
    self.parentViewController.navigationItem.title = self.title;
    [super viewWillAppear:animated];
}

- (void) refreshData:(BOOL)forceRefresh
{
    if( !self.hasLoadedData || forceRefresh)
    {
        [self updateContent];
        self.hasLoadedData = YES;
    }
}

- (NSArray *) normalObjects
{
    return [self.row longDescriptionInArray:YES];
}

- (NSArray *) hiddenObjects
{
    return [self.row longDescriptionInArray:NO];
}

- (void) sizeChanged
{
    if( [self.parentViewController isKindOfClass:[DetailsPagesController class]])
    {
        [(DetailsPagesController *)self.parentViewController markViewControllersAsDirty];
    }
    [self refreshData:YES];
}
    
- (int) getPointsChange:(UIPinchGestureRecognizer *)pinch
{
    CGFloat currentPoints = [CSVPreferencesController detailsFontSize];
    CGFloat scaledPoints = pinch.scale * self.originalPointsWhenPinchStarted;
    return (scaledPoints - currentPoints);
}

- (void) applyPointsChange:(int)pointsChange
{
    if( pointsChange == 0 )
        return;
    
    [CSVPreferencesController changeDetailsFontSize:pointsChange];
    [self sizeChanged];
}

- (void) pinch:(UIPinchGestureRecognizer *)pinch
{
    switch(pinch.state)
    {
        case UIGestureRecognizerStateBegan:
            self.originalPointsWhenPinchStarted = [CSVPreferencesController detailsFontSize];
            // Intentional fallthrough!
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            [self applyPointsChange:[self getPointsChange:pinch]];
            break;
        default:
            break;
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
        [s appendString:@"localfile://"];
        [s appendString:[[CSV_TouchAppDelegate localMediaDocumentsPath] stringByAppendingPathComponent:[tmpArray objectAtIndex:1]]];
        return s;
    }
    else
        return localURL;
}

- (void) delayedHtmlClick:(NSURL *)URL
{
    [[UIApplication sharedApplication] openURL:URL
                                       options:[NSDictionary dictionary]
                             completionHandler:nil];
}

- (void) imageWasShown
{
    self.imageShown = YES;
    [self.webView removeGestureRecognizer:self.pinchGesture];
}

- (BOOL) useDarkCSS
{
    if( @available(iOS 13, *))
    {
        return self.view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    }
    return NO;
}
- (void) addHtmlHeader:(NSMutableString *)s useSingleColumn:(BOOL)useSingleColumn
{
    NSString *cssString = (useSingleColumn ?
                           [CSSProvider singleColumnCSSForDarkMode:[self useDarkCSS]] :
                           [CSSProvider doubleColumnCSSForDarkMode:[self useDarkCSS]]);

    [s appendString:@"<html><head><title>Details</title>"];
    [s appendString:@"<style type=\"text/css\">"];
    [s appendString:cssString];
    [s appendString:@"</style>"];
    [s replaceOccurrencesOfString:@"FONTSIZE"
                       withString:[NSString stringWithFormat:@"%fpx", [CSVPreferencesController detailsFontSize]]
                          options:0
                            range:NSMakeRange(0, [s length])];
    [s appendString:@"</head>"];
}

- (void) addHtmlTable:(NSMutableString *)s
{
    NSMutableString *data = [NSMutableString string];
    NSArray *columnsAndValues = [self.row columnsAndValues];
    NSInteger row = 1;
    BOOL hideEmptyColumns = [CSVPreferencesController hideEmptyColumns];
    for( NSDictionary *d in columnsAndValues )
    {
        // Are we done already?
        if(row > [self.row.fileParser.shownColumnIndexes count] &&
           ![CSVPreferencesController showDeletedColumns])
            break;
        
        if( hideEmptyColumns && ([d objectForKey:VALUE_KEY] == NULL || [[d objectForKey:VALUE_KEY] isEqualToString:@""]))
            continue;
        
        // Indicating start of hidden columns
        if(row != 1 && // In case someone has a file where no column is important...
           row-1 == [self.row.fileParser.shownColumnIndexes count] &&
           [self.row.fileParser.shownColumnIndexes count] != [columnsAndValues count] )
        {
            [data appendString:@"<tr class=\"rowstep\"><th><b> </b><td>"];
        }
        
        [data appendFormat:@"<tr%@><th>%@",
         ((row % 2) == 1 ? @" class=\"odd\"" : @""),
         [d objectForKey:COLUMN_KEY]];
        if( [[d objectForKey:VALUE_KEY] containsImageURL] && [CSVPreferencesController showInlineImages] )
        {
            [data appendFormat:@"<td><img src=\"%@\">", [d objectForKey:VALUE_KEY]];
            [self imageWasShown];
        }
        else if( [[d objectForKey:VALUE_KEY] containsLocalImageURL] && [CSVPreferencesController showInlineImages] )
        {
            [data appendFormat:@"<td><img src=\"%@\"></img>", [DetailsViewController sandboxedFileURLFromLocalURL:[d objectForKey:VALUE_KEY]]];
            [self imageWasShown];
        }
        else if( [[d objectForKey:VALUE_KEY] containsLocalMovieURL] && [CSVPreferencesController showInlineImages] )
        {
            [data appendFormat:@"<td><video src=\"%@\" controls x-webkit-airplay=\"allow\"></video>", [DetailsViewController sandboxedFileURLFromLocalURL:[d objectForKey:VALUE_KEY]]];
            [self imageWasShown];
        }
        else if( [[d objectForKey:VALUE_KEY] containsURL] )
            [data appendFormat:@"<td><a href=\"%@\">%@</a>", [d objectForKey:VALUE_KEY], [d objectForKey:VALUE_KEY]];
        else if( [[d objectForKey:VALUE_KEY] containsMailAddress] )
            [data appendFormat:@"<td><a href=\"mailto:%@\">%@</a>", [d objectForKey:VALUE_KEY], [d objectForKey:VALUE_KEY]];
        else
            [data appendFormat:@"<td>%@", [d objectForKey:VALUE_KEY]];
        row++;
    }

    [s appendString:@"<table>"];
    [s appendString:data];
    [s appendFormat:@"</table>"];
}

- (void) addSimpleHtmlTable:(NSMutableString *)s
{
    NSMutableString *data = [NSMutableString string];
    NSArray *columnsAndValues = [self.row columnsAndValues];
    NSInteger row = 1;
    BOOL hideEmptyColumns = [CSVPreferencesController hideEmptyColumns];
    for( NSDictionary *d in columnsAndValues )
    {
        // Are we done already?
        if(row > [self.row.fileParser.shownColumnIndexes count] &&
           ![CSVPreferencesController showDeletedColumns])
            break;
                
        if( hideEmptyColumns && ([d objectForKey:VALUE_KEY] == NULL || [[d objectForKey:VALUE_KEY] isEqualToString:@""]))
            continue;

        // Indicating start of hidden columns
        if(row != 1 && // In case someone has a file where no column is important...
           row-1 == [self.row.fileParser.shownColumnIndexes count] &&
           [self.row.fileParser.shownColumnIndexes count] != [columnsAndValues count] )
        {
            [data appendString:@"</table><br><br><table>"];
        }
        
        [data appendFormat:@"<tr><td>%@: %@",
         [d objectForKey:COLUMN_KEY],
         [d objectForKey:VALUE_KEY]];
        row++;
    }
    [s appendString:@"<br><table>"];
    [s appendString:data];
    [s appendFormat:@"</table>"];
}

- (void) addSimpleRowRepresentation:(NSMutableString *)s
{
    NSMutableString *row = [NSMutableString stringWithString:[self.row htmlDescriptionWithHiddenValues:[CSVPreferencesController showDeletedColumns]
                                                                                      hideEmptyColumns:[CSVPreferencesController hideEmptyColumns]]];
    [s appendString:row];
}

- (void) updateContent
{
    [self.webView stopLoading];
    NSMutableString *s = [NSMutableString string];
    NSInteger viewToSelect = [CSVPreferencesController selectedDetailsView];
    if( viewToSelect == 0 ){
        [self addHtmlHeader:s useSingleColumn:NO];
        [s appendString:@"<body>"];
        [self addHtmlTable:s];
    }
    else if( viewToSelect == 1 ){
        [self addHtmlHeader:s useSingleColumn:YES];
        [s appendString:@"<body>"];
        [self addSimpleRowRepresentation:s];
    }
    else if( viewToSelect == 2 ){
        [self addHtmlHeader:s useSingleColumn:YES];
        [s appendString:@"<body>"];
        [self addSimpleHtmlTable:s];
    }
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

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if( !self.imageShown && [otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] )
    {
        [otherGestureRecognizer setState:UIGestureRecognizerStateEnded];
        return YES;
    }
    
    return NO;
}

@end
