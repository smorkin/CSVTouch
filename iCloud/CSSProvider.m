//
//  CSSProvider.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2019-02-06.
//

#import "CSSProvider.h"
#import "SimpleDocument.h"

#ifdef CSV_LITE
static NSString *UbiquityContainerIdentifier = @"iCloud.se.ozymandias.csvlite";
#else
static NSString *UbiquityContainerIdentifier = @"iCloud.se.ozymandias.csvtouch";
#endif

static NSString *customCSSFolder = @"custom_css";

@implementation CSSProvider

+ (void) startCustomCssRetrieving
{
    [SimpleDocument start];
}

+ (NSString *) doubleColumnCSS
{
    NSString *custom = [SimpleDocument customCssString];
    if( custom && ![custom isEqualToString:@""])
        return custom;
    
    return [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"doublecolumn" ofType:@"css"]
                                      usedEncoding:nil
                                             error:NULL];
}

+ (NSString *) singleColumnCSS
{
    return [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"singlecolumn" ofType:@"css"]
                                 usedEncoding:nil
                                        error:NULL];
}

+ (NSURL*) ubiquitousContainerURL
{
    return [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:UbiquityContainerIdentifier];
}

+ (NSURL*) ubiquitousDocumentsDirectoryURL
{
    return [[self ubiquitousContainerURL] URLByAppendingPathComponent:@"Documents" isDirectory:YES];
}

@end
