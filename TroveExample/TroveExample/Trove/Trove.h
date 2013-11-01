//
//  Trove.h
//  Trove
//
//  Created by Mikhail Sinanan on 7/16/13.
//  Copyright (c) 2013 NPR. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TroveDelegate <NSObject>
@optional

- (void)assetDownloadSuccessful;
- (void)assetDownloadFailed;

@end

@interface Trove : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    
    id <TroveDelegate> delegate;
}

+ (Trove *) sharedInstance;

// Initiates download
- (void)cacheAsset:(NSURL *)url;

// Either on disk or on the server if not cached
- (NSURL*)assetURL:(NSURL *)url ;

// Kill all inflight cache requests
- (void)cancelAllRequests;

@property (nonatomic, retain) id <TroveDelegate> delegate;

@end
