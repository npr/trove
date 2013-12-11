//
//  Trove.h
//  Trove
//
//  Created by Mikhail Sinanan on 7/16/13.
//  Copyright (c) 2013 NPR. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 This class stores and retrieves media assets from the supplied URLs. 
 It uses NSOperationQueue to handle NSURLConnections, that download the 
 assets asynchronously.
 
 The class uses the sharedInstance singleton pattern, as such the init is never
 called directly.
 
 Access by calling the Class Method:
 [Trove sharedInstance]
 
 */

@protocol TroveDelegate <NSObject>
@optional

/** Alerts the delegate the asset has completed downloading
    and returns the file path */
- (void)assetDownloadSuccessful:(NSURL*)assetPath;

/** Alerts the delegate the asset has failed downloading
 and returns an NSError */
- (void)assetDownloadFailed:(NSError*)error;

@end

@interface Trove : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    
    id <TroveDelegate> delegate;
}

@property (nonatomic, retain) id <TroveDelegate> delegate;

/**-----------------------------------------------------------------------------
 * @name Class Methods
 *  ----------------------------------------------------------------------------
 */

/** Singleton pattern used to call Trove
 
 @return Trove the shared instance
 */
+ (Trove *) sharedInstance;


/** Initiates the NSOperation, that will download the asset
 
    @param NSURL the url to the media asset
 */
- (void)cacheAsset:(NSURL *)url;

/** Returns the media asset file path, either on disk or on
    the server if not cached
 
    @param NSURL the original URL used to cache the media asset
    @return NSURL file URL to media asset
 */
- (NSURL*)assetURL:(NSURL *)url ;


/** Stops all in-progress NSOperations in the queue
 */
- (void)cancelAllRequests;



@end
