//
//  Trove.h
//  Trove
//
//  Created by Mikhail Sinanan on 7/16/13.
//  Copyright (c) 2013 NPR. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DelegateSuccess) (NSData *theData);
typedef void (^DelegateFailure) (NSError *theError);
typedef void (^DelegateComplete) (NSString *completeURL);

@interface Trove : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    
}

+ (Trove *) sharedInstance;

// Initiates download
- (void)cacheAsset:(NSURL *)url;

// Either on disk or on the server if not cached
- (NSURL*)assetURL:(NSURL *)url ;

// Kill all inflight cache requests
- (void)cancelAllRequests;

@end
