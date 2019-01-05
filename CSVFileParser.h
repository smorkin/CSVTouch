//
//  CSVFileParser.h
//  CSV Touch
//
//  Created by Simon Wigzell on 03/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OzymandiasAdditions.h"
#import "CSVRow.h"

#define DEFAULT_ENCODING 0

@interface CSVFileParser : NSObject {
}
@property (nonatomic, strong) NSMutableArray<CSVRow*> *parsedItems;
@property (nonatomic, strong) NSMutableArray *columnNames;
@property (nonatomic, strong) NSMutableIndexSet *predefineHiddenColumns; // Just used temporary, for a newly downloaded file
@property (nonatomic, assign) int *rawShownColumnIndexes;
@property (nonatomic, strong) NSMutableArray *shownColumnIndexes;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *URL;
@property (nonatomic, copy) NSDate *downloadDate;
@property (nonatomic, readonly) NSString *rawString;
@property (nonatomic, copy) NSString *problematicRow;
@property (nonatomic, assign) BOOL hasBeenParsed;
@property (nonatomic, assign) BOOL hasBeenDownloaded;
@property (nonatomic, assign) BOOL hasFailedToDownload;
@property BOOL isSorted;
@property (nonatomic, assign) NSUInteger iconIndex;
@property (nonatomic, assign) BOOL hideAddress;

// All currently avaialbe files sorted using file name
+ (NSMutableArray *) files;
+ (void) removeAllFiles;

+ (void) removeFile:(CSVFileParser *)parser;
+ (void) removeFileWithName:(NSString *) name;

+ (BOOL) fileExistsWithURL:(NSString *)URL;

+ (void) saveColumnNames;

+ (CSVFileParser *) addParserWithRawData:(NSData *)data forFilePath:(NSString *)path;
+ (CSVFileParser *) existingParserForName:(NSString *)name;

+ (void) resetClearingOfDownloadFlagsTimer;
+ (void) clearAllDownloadFlags;

+ (void) fixedWidthSettingsChangedUsingUI;

- (void) saveToFile;

- (NSData *) fileRawData;;

- (void) parseIfNecessary;
- (void) reparseIfParsed;

- (void) invalidateShortDescriptions;

- (NSMutableArray *)shownColumnNames;

// Updates the hidden/shown stuff
- (void) updateColumnsInfo;
- (void) updateColumnsInfoWithShownColumns:(NSArray *)shown;

// Will show all columns
- (void) resetColumnsInfo;

// Convenience
- (BOOL) hiddenColumnsExist;

- (void) encodingUpdated;

- (NSString *) fileName;
- (NSUInteger) stringLength;

- (BOOL) downloadedLocally;

- (unichar) delimiter;

- (NSString *) parseErrorString;

+ (NSArray *) allowedFileEncodings; // NSUIntegers
+ (NSArray *) allowedFileEncodingNames;

@end

@interface CSVFileParser (OzyTableViewProtocol) <OzyTableViewObject>
- (NSString *) defaultTableViewDescription;
- (NSComparisonResult) compareFileName:(CSVFileParser *)fp;
@end

@interface CSVFileParser (Preferences)

+ (void) setFileEncoding:(NSStringEncoding)encoding forFile:(NSString *)fileName;
+ (void) removeFileEncodingForFile:(NSString *) fileName;
// Returns an actual good encoding
+ (NSStringEncoding) getEncodingForFile:(NSString *)fileName;
// Returns the actual setting, i.e. possibly DEFAULT_ENCODING
+ (NSUInteger) getEncodingSettingForFile:(NSString *)fileName;

@end


