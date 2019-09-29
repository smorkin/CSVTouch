//
//  CSSProvider.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2019-02-06.
//

#import "CSSProvider.h"

#define MULTICOLUMNNAME @"doublecolumn"
#define SINGLECOLUMNNAME @"singlecolumn"
#define MULTICOLUMNNAMEDARK @"doublecolumn_dark"
#define SINGLECOLUMNNAMEDARK @"singlecolumn_dark"

@interface SimpleDocument : UIDocument
@property (strong, nonatomic) NSString* documentText;
@end

@implementation CSSProvider

static NSMetadataQuery *_icloudQuery;
static NSString *_customMultiColumnCssString;
static NSString *_customSingleColumnCssString;
static NSString *_standardMultiColumnCssString;
static NSString *_standardSingleColumnCssString;
static NSString *_standardMultiColumnCssDarkString;
static NSString *_standardSingleColumnCssDarkString;

+ (BOOL) customCSSExists
{
    return _customSingleColumnCssString != nil || _customMultiColumnCssString != nil;
}

+ (NSMetadataQuery *)documentQuery {
    
    NSMetadataQuery * query = [[NSMetadataQuery alloc] init];
    // Search documents subdir only
    [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
    
    // Add a predicate for finding the documents
    // NSPredicate requires the whole LIKE entry to be a single string (it puts "" around it) so we need to put the whole file name together before building the predicate
    NSString *multiName = [NSString stringWithFormat:@"%@.css", MULTICOLUMNNAME];
    NSString *singleName = [NSString stringWithFormat:@"%@.css", SINGLECOLUMNNAME];
    NSPredicate *multiPattern = [NSPredicate predicateWithFormat:@"%K LIKE %@",
                                 NSMetadataItemFSNameKey, multiName];
    NSPredicate *singlePattern = [NSPredicate predicateWithFormat:@"%K LIKE %@",
                                  NSMetadataItemFSNameKey, singleName];
    [query setPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:@[multiPattern, singlePattern]]];
    return query;
}

+ (void) startCustomCssRetrieving
{
    if( !_icloudQuery)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processiCloudFiles:)
                                                     name:NSMetadataQueryDidFinishGatheringNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processiCloudFiles:)
                                                     name:NSMetadataQueryDidUpdateNotification
                                                   object:nil];
        _icloudQuery = [self documentQuery];
        [_icloudQuery startQuery];
    }
}

+ (void) setCustomMultiColumnCssString:(NSString *)custom
{
    _customMultiColumnCssString = [custom copy];
}

+ (NSString *) customMultiColumnCssString
{
    return _customMultiColumnCssString;
}

+ (void) setCustomSingleColumnCssString:(NSString *)custom
{
    _customSingleColumnCssString = [custom copy];
}

+ (NSString *) customSingleColumnCssString
{
    return _customSingleColumnCssString;
}

+ (void)processiCloudFiles:(NSNotification *)notification {
    // Always disable updates while processing results
    [_icloudQuery disableUpdates];
    
    // The query reports all files found, every time.
    NSLog(@"Found iCloud custom files: %@",[_icloudQuery results].count > 0 ? @"YES" : @"NO");
    BOOL foundCustomMultiCssFile = NO;
    BOOL foundCustomSingleCssFile = NO;
    // NOTE! Queries always return the full file set -> if one of multi/single files is not here, it doesn't exist
    for (NSMetadataItem * result in [_icloudQuery results])
    {
        // Ignore while downloading...
        if( [[result valueForAttribute:@"NSMetadataUbiquitousItemIsDownloadingKey"] boolValue] )
            continue;
        NSURL * fileURL = [result valueForAttribute:NSMetadataItemURLKey];
        NSNumber *fileIsHiddenKey = nil;
        
        // Don't include hidden files
        [fileURL getResourceValue:&fileIsHiddenKey forKey:NSURLIsHiddenKey error:nil];
        if ((!fileIsHiddenKey || ![fileIsHiddenKey boolValue]) &&
            ![[fileURL path] containsString:@".Trash"]) {
            BOOL isMultipleUpdate = [[fileURL path] containsString:MULTICOLUMNNAME];
            SimpleDocument *sd = [[SimpleDocument alloc] initWithFileURL:fileURL];
            if( isMultipleUpdate)
                foundCustomMultiCssFile = TRUE;
            else
                foundCustomSingleCssFile = TRUE;
            if( [sd readFromURL:sd.fileURL error:nil])
            {
                if( sd.documentText && ![sd.documentText isEqualToString:@""] &&
                   ![sd.documentText isEqualToString:[self customMultiColumnCssString]])
                {
                    NSLog(@"Setting new custom %@ css string", (isMultipleUpdate ? @"multi-column" : @"single column"));
                    if( isMultipleUpdate)
                        [self setCustomMultiColumnCssString:sd.documentText];
                    else
                        [self setCustomSingleColumnCssString:sd.documentText];
                }
            }
            else
            {
                [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:fileURL error:nil];
            }
        }
    }
    
    if( !foundCustomMultiCssFile )
    {
        [self setCustomMultiColumnCssString:nil];
    }
    if( !foundCustomSingleCssFile )
    {
        [self setCustomSingleColumnCssString:nil];
    }
    [_icloudQuery enableUpdates];
}

+ (NSString *) doubleColumnCSSDark
{
    // The standard one cannot change while app is running -> cache it
    if( !_standardMultiColumnCssDarkString )
        _standardMultiColumnCssDarkString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:MULTICOLUMNNAMEDARK ofType:@"css"]
                                                              usedEncoding:nil
                                                                     error:NULL];
    
    return _standardMultiColumnCssDarkString;
}

+ (NSString *) doubleColumnCSS
{
    // The standard one cannot change while app is running -> cache it
    if( !_standardMultiColumnCssString )
        _standardMultiColumnCssString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:MULTICOLUMNNAME ofType:@"css"]
                                                              usedEncoding:nil
                                                                     error:NULL];
    
    // Now, return custom string if it exists
    return ( _customMultiColumnCssString && ![_customMultiColumnCssString isEqualToString:@""]) ?
    _customMultiColumnCssString : _standardMultiColumnCssString;
}

+ (NSString *) singleColumnCSSDark
{
    if( !_standardSingleColumnCssDarkString )
        _standardSingleColumnCssDarkString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:SINGLECOLUMNNAMEDARK ofType:@"css"]
                                                               usedEncoding:nil
                                                                      error:NULL];
    
    return _standardSingleColumnCssDarkString;
}

+ (NSString *) singleColumnCSS
{
    if( !_standardSingleColumnCssString )
        _standardSingleColumnCssString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:SINGLECOLUMNNAME ofType:@"css"]
                                                               usedEncoding:nil
                                                                      error:NULL];

    return ( _customSingleColumnCssString && ![_customSingleColumnCssString isEqualToString:@""]) ?
    _customSingleColumnCssString : _standardSingleColumnCssString;
}

+ (NSString *) singleColumnCSSForDarkMode:(BOOL)dark
{
    return dark ? [self singleColumnCSSDark] : [self singleColumnCSS];
}

+ (NSString *) doubleColumnCSSForDarkMode:(BOOL)dark
{
    return dark ? [self doubleColumnCSSDark] : [self doubleColumnCSS];
}

@end

@implementation SimpleDocument

- (instancetype) initWithFileURL:(NSURL *)url
{
    self = [super initWithFileURL:url];
    return self;
}

- (BOOL) hasUnsavedChanges
{
    return NO;
}

- (BOOL)loadFromContents:(id)contents
                  ofType:(NSString *)typeName
                   error:(NSError **)outError {
    if ([contents length] > 0)
        self.documentText = [[NSString alloc]
                             initWithData:contents
                             encoding:NSUTF8StringEncoding];
    else
        self.documentText = @"";
    
    return YES;
}

@end
