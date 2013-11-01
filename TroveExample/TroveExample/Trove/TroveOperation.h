//
//  TroveOperation.h
//  Trove
//
//  Created by Michael Seifollahi on 8/22/13.
//  Copyright (c) 2013 NPR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TroveOperation : NSOperation

@property (nonatomic, readonly) NSError* error;
@property (nonatomic, readonly) NSURL *connectionURL;

- (id)initWithURL:(NSURL *)url saveToFilePath:(NSString *)filePath;

@end
