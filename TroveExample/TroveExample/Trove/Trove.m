//
//  Trove.m
//  Trove
//
//  Created by Mikhail Sinanan on 7/16/13.
//  Copyright (c) 2013 NPR. All rights reserved.
//

#import "Trove.h"
#import "Reachability.h"
#import "TroveOperation.h"

@interface Trove ()

@property (nonatomic,readwrite,strong) NSOperationQueue *networkQueue;
@property (nonatomic,readwrite) NSTimeInterval timeout;
@property (nonatomic,readwrite) NSURLRequestCachePolicy cachePolicy;
@property (nonatomic,readwrite) NSOperationQueuePriority queuePriority;

@end

/*
 * We encode the data associated with an asset
 * under the url-escaped absolute asset url
 */
 //Relative paths
#define ASSET_CACHE_DIR @"/assets"

// If it's in this directory, it's done downloading
// and ready to be served up
#define DONE_DIR @"/done"

// Can't be a #define since most wait till load
const NSString* ROOT_CACHE_DIR;

//Size of cached assets in DONE_DIR
#define CACHE_SIZE 100*1e6


@implementation Trove


+ (void)initialize {
    
    if ( self == [Trove class] ) {
    // Ensure all directories needed are created
    NSFileManager *filemgr = [NSFileManager defaultManager];
    ROOT_CACHE_DIR = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
    for (NSString* dirPath in @[DONE_DIR]) {
        NSString* path = [NSString stringWithFormat:@"%@%@%@", ROOT_CACHE_DIR, ASSET_CACHE_DIR, dirPath];
        if(![self doesFileExist:path]) {
            NSError* err;
            [filemgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
        }
    }
    }
}

+(Trove *)sharedInstance {
    static Trove *instance;
    
    @synchronized(self) {
        if(!instance) {
            instance = [[Trove alloc] init];
        }
    }
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _networkQueue = [NSOperationQueue new];
        
        //If on wifi, increase concurrent connections
        if ( [self.class networkIsWifi] ) {
            _networkQueue.maxConcurrentOperationCount = 1;
        } else {
            _networkQueue.maxConcurrentOperationCount = 1;
        }
        _timeout = 30.0;
        _cachePolicy = NSURLRequestUseProtocolCachePolicy;
        _queuePriority = NSOperationQueuePriorityNormal;

    }
    return self;
}

// Absolute file path if the asset was finished in cache
+ (NSString*)finishedAssetPath:(NSURL*)assetURL {
    
    if (assetURL == nil) {
        return nil;
    }
    
    NSString *finishedPath = [NSString stringWithFormat:@"%@%@%@/%@", ROOT_CACHE_DIR, ASSET_CACHE_DIR, DONE_DIR,[self properURLEncode:assetURL.absoluteString]];
    return finishedPath;
}

+ (BOOL)doesFileExist:(NSString*)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

//Detect faster networks such as Wifi 
+ (BOOL) networkIsWifi {
    Reachability *reach = [Reachability reachabilityForLocalWiFi];
    [reach startNotifier];
    
    NetworkStatus stat = [reach currentReachabilityStatus];
    if(stat & ReachableViaWiFi) {
        //reachable via wifi
        return YES;
    }
    return NO;
}

//Returns the size of a folder 
+ (unsigned long long int)folderSize:(NSString *)folderPath {
    
    if ( folderPath == nil || folderPath.length == 0 ) {
        return 0;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:folderPath]){
        return 0;
    }
    
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long int fileSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDictionary fileSize];
    }
    
    return fileSize;
}
/**
 * Returns oldest files from directory `path` until `numBytes` accumulated files. Returns
 * array of file names
 */
+ (NSArray*) oldestFilesInPath:(NSString*)path ofTotalSize:(long long)numBytes  {
    
    if ( path == nil || path.length == 0 || numBytes < 0 ) {
        return nil;
    }
    
     NSFileManager* filemgr = [NSFileManager defaultManager];
    if (![filemgr fileExistsAtPath:path]){
        return nil;
    }
   
    NSError* err ;
    NSArray* files = [filemgr contentsOfDirectoryAtPath:path error:&err];
    NSArray* sortedFiles = [files sortedArrayUsingComparator:^(NSString* f1, NSString* f2) {
        NSString* filePath1 = [path stringByAppendingPathComponent:f1];
        NSString* filePath2 = [path stringByAppendingPathComponent:f2];
        NSDate* createDate1 = [filemgr attributesOfItemAtPath:filePath1 error:nil][NSFileModificationDate];
        NSDate* createDate2 = [filemgr attributesOfItemAtPath:filePath2 error:nil][NSFileModificationDate];
        NSComparisonResult compareResult =  [createDate1 compare:createDate2];
        return compareResult;
    }];
    NSMutableArray* oldfiles = [NSMutableArray new];
    long long numBytesDeleted = 0;
    for (int i=0; (i < sortedFiles.count) && (numBytesDeleted < numBytes); i++) {
        NSString* filePath = [path stringByAppendingPathComponent:sortedFiles[i]];
        NSDictionary* fileAttrs = [filemgr attributesOfItemAtPath:filePath error:&err];
        long long fileSizeInBytes = [fileAttrs[NSFileSize] longLongValue];
        numBytesDeleted += fileSizeInBytes;
        [oldfiles addObject:filePath];
    }
    return oldfiles;
}

/* Check DONE_DIR directory file size
 * If greater than desired size, start pruning files until directory is desired size
 */

- (void) pruneAssetsInCache {
    
    NSString* doneDirPath = [NSString stringWithFormat:@"%@%@%@", ROOT_CACHE_DIR, ASSET_CACHE_DIR, DONE_DIR];
    long long dirSize = [self.class folderSize:doneDirPath];

    if ( dirSize > CACHE_SIZE ) {
        
        NSArray* filesToDelete = [self.class oldestFilesInPath:doneDirPath ofTotalSize:(dirSize - CACHE_SIZE)];
        
        for (int i=0; i < [filesToDelete count]; i++) {
            
            NSURL* url = [NSURL fileURLWithPath:filesToDelete[i]];
            //NSLog(@"DELETED FILE at %@", fileToDeletePath);
            NSError* error;
            [[NSFileManager defaultManager] removeItemAtPath:url.relativePath error: &error];
            #ifdef DEBUG
                if (error) {
                    NSLog(@"File Delete ERROR:%@", error);
                }
            #endif
        }
    }
}

+ (NSString*) properURLEncode:(NSString*)str {
    
    if ( str == nil || str.length == 0 ) {
        return nil;
    }
    
    NSRange range = [str rangeOfString:@"?"];
    str = range.length > 0 ? [str substringToIndex:range.location] : str;
    
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
    return result;
}

/*
 *  Create an TroveOperation and add it to the queue.
 */
- (void)addOperationForURL:(NSURL *)url
{
    // Always suspend the queue before adding more operations or you will have a bad time.
    if (![self.networkQueue isSuspended]) {
        [self.networkQueue setSuspended:YES];
    }
    
    TroveOperation *cacheOp = [[TroveOperation alloc] initWithURL:url saveToFilePath:[self.class finishedAssetPath:url]];
    [cacheOp setQueuePriority:NSOperationQueuePriorityNormal];
    [cacheOp addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:NULL];
    [cacheOp setCompletionBlock:^{
        //Check cache size and prune if necessary
        [self pruneAssetsInCache];
        
        //Let the delegate know
    }];
    [self.networkQueue addOperation:cacheOp];
    
    [self.networkQueue setSuspended:NO];
}


// Initiates download
- (void)cacheAsset:(NSURL *)url  {
    if (url == nil) {
        NSLog(@"URL can't be nil");
        return;
    }
    
    // If already downloaded or inflight don't bother
    if ( [self.class doesFileExist:[self.class finishedAssetPath:url]] ) {
        return;
    }
    
    [self addOperationForURL:url];
}

// Either on disk or on the server if not cached
- (NSURL*)assetURL:(NSURL *)url  {
    NSString* onDiskPath = [self.class finishedAssetPath:url];
    // If finished on disk, return file url
    if ([self.class doesFileExist:onDiskPath]) {
//        NSLog(@"File exists on disk: %@", onDiskPath);
//        NSLog(@"File length on disk: %d", [[[NSFileManager defaultManager] contentsAtPath:onDiskPath] length]);
        
        return [NSURL fileURLWithPath:onDiskPath];
    }
    
    return url;
}

// Kill all pending cache requests from the operation and removes
// the partially written inflight files from disk
- (void)cancelAllRequests {
    for (NSOperation *op in [self.networkQueue operations]) {
        [op cancel];
    }
    
    [self.networkQueue setSuspended:YES];
    [self.networkQueue cancelAllOperations];

    [self.networkQueue setSuspended:NO];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // TODO: Handle errors (if needed)
    NSError *error;
    
    if ([object isKindOfClass:[TroveOperation class]]) {
        TroveOperation *cacheOp = (TroveOperation *)object;
        error = [cacheOp error];
        
        if (error != nil) {
            NSLog(@"Error encountered while precaching: %@", error);
        }
        
        [cacheOp removeObserver:self forKeyPath:@"isFinished"];
        cacheOp = nil;
    }
}

@end
