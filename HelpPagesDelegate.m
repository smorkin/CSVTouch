//
//  HelpPagesDelegate.m
//  Heartfeed
//
//  Created by Simon Wigzell on 2018-11-28.
//  Copyright © 2018 Ozymandias. All rights reserved.
//

#import "HelpPagesDelegate.h"
#import "HelpPagesViewController.h"
#import "CSVPreferencesController.h"

@implementation HelpPagesDelegate

- (NSInteger) numberOfPages
{
    return 7;
}

- (NSString *) textForHelpPage:(NSInteger)index
{
    NSString *appName = NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"];
    switch(index)
    {
        case 0:
        {
            NSMutableString *s = [NSMutableString stringWithString:@"Welcome! To get started, you first need to get your CSV file(s) into the app. There are multiple ways of doing this, presented on the following pages.\n\nIf you instead want to see the complete documentation, go here:\n\nhttp://csvtouch.wordpress.com"];
            if( [CSVPreferencesController restrictedDataVersionRunning])
            {
                [s appendString:@"\n\nNOTE: This free version is restricted to only showing the 150 first items in a file."];
            }
            return s;
        }
        case 1:
            return @"To import files from within the app, start by pressing the '+' button on the start page.";
        case 2:
            return @"Add using URL: Here you input a web address to a CSV file which will then be downloaded.\nAdd using URL for list of files: Here you also input a web address but for a text file containing addresses to multiple files for quick import of them.\nImport local file: Click to open the iOS file browser. From there, select your CSV file.\nSee http://csvtouch.wordpress.com for more details.";
        case 3:
            return @"Inside any other iOS app which supports export/sharing of files, you can select a CSV file and then import it.";
        case 4:
            return  [NSString stringWithFormat:@"If you connect your device to your computer, you can add CSV files directly in the same way you add files to any app: Select the device, go to 'Files', select %@, and add the files.", appName];
        case 5:
            return [NSString stringWithFormat:@"Finally, there are some more unusual ways of getting your files into %@ and other customisations possible. See the full documentation at http://csvtouch.wordpress.com", appName];
        case 6:
            return @"If the app has problems reading an imported file, please try toggling the \"Alternative parsing\" and/or the \"Keep quotes\" setting in the 'Files' view, or change the used file encoding. If you are having problems or need to understand all the other settings (which might also help), please check the full documentation at http://csvtouch.wordpress.com. If that still doesn't help, you can always mail me (email address available in the AppStore) 🙂";
        default:
            return @"";
    }
}

- (NSString *) titleForHelpPage:(NSInteger)index
{
    switch(index)
    {
        case 0:
            return NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"];
        case 1:
            return @"Importing from inside the app";
        case 2:
            return @"Options";
        case 3:
            return @"Files, Mail, Dropbox, ...";
        case 4:
            return @"Computer";
        case 5:
            return @"Advanced";
        case 6:
            return @"Troubleshooting";
        default:
            return @"";
    }
}

- (UIImage *) imageForHelpPage:(NSInteger)index
{
    switch(index)
    {
        case 0:
            return [UIImage imageNamed:@"next.png"];
        case 1:
            return [UIImage imageNamed:@"add_file_button.png"];
        case 2:
            return [UIImage imageNamed:@"add_file_options.png"];
        case 3:
            return [UIImage imageNamed:@"file_via_mail.png"];
        case 4:
            return [UIImage imageNamed:@"files_via_finder.png"];
        default:
            return nil;
    }
}

- (void) helpPagesShowCompleted:(HelpPagesViewController *)controller
{
//    if( [[[FeedCollector sharedInstance] feeds] count] == 0 )
//    {
//        [[MainViewController sharedInstance] performSelector:@selector(feedListEdit:)
//                                                  withObject:self
//                                                  afterDelay:0.1];
//    }
}

@end
