//
//  SimpleDocument.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2019-02-08.
//

#import "SimpleDocument.h"

@implementation SimpleDocument

static NSMetadataQuery *_icloudQuery;

+ (NSMetadataQuery *)documentQuery {
    
    NSMetadataQuery * query = [[NSMetadataQuery alloc] init];
    if (query) {
        
        // Search documents subdir only
        [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
        
        // Add a predicate for finding the documents
        NSString * filePattern = @"csv_doublecolumn.css";
        [query setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE %@",
                             NSMetadataItemFSNameKey, filePattern]];
    }
    return query;
    
}

+ (void) start
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

+ (void) stop
{
    if( _icloudQuery)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [_icloudQuery stopQuery];
        _icloudQuery = nil;
    }
}

static NSString *_customCssString;

+ (void) setCustomCss:(NSString *)custom
{
    _customCssString = [custom copy];
}

+ (NSString *) customCssString
{
    return _customCssString;
}

+ (void)processiCloudFiles:(NSNotification *)notification {
    // Always disable updates while processing results
    [_icloudQuery disableUpdates];
    
    // The query reports all files found, every time.
    NSLog(@"Found iCloud custom files: %@",[_icloudQuery results].count > 0 ? @"YES" : @"NO");
    BOOL foundCustomCssFile = NO;
    for (NSMetadataItem * result in [_icloudQuery results])
    {
        NSURL * fileURL = [result valueForAttribute:NSMetadataItemURLKey];
        NSNumber *fileIsHiddenKey = nil;
        
        // Don't include hidden files
        [fileURL getResourceValue:&fileIsHiddenKey forKey:NSURLIsHiddenKey error:nil];
        if ((!fileIsHiddenKey || ![fileIsHiddenKey boolValue]) &&
            ![[fileURL path] containsString:@".Trash"]) {
            foundCustomCssFile = YES;
            SimpleDocument *sd = [[SimpleDocument alloc] initWithFileURL:fileURL];
            if( [sd readFromURL:sd.fileURL error:nil])
            {
                NSLog(@"Setting new custom css synch");
                [self setCustomCss:sd.documentText];
            }
            else
            {
                [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:fileURL error:nil];
            }
        }
    }
    
    if( !foundCustomCssFile )
    {
        [self setCustomCss:nil];
//        customCssFileChangeDateCurrent = nil;
    }
    [_icloudQuery enableUpdates];
}

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
        self.documentText = nil;
    
    return YES;
}

@end
