//
//  TroveOperation.m
//  Trove
//
//  Created by Michael Seifollahi on 8/22/13.
//  Copyright (c) 2013 NPR. All rights reserved.
//

#import "TroveOperation.h"

@interface TroveOperation()

    // KVO of the opertaion state
    @property (nonatomic) BOOL executing;
    @property (nonatomic) BOOL finished;

    @property (nonatomic, strong) NSURLConnection *connection;
    @property (nonatomic, strong) NSString *filePath;
    @property (nonatomic, strong) NSOutputStream *stream;

@end

@implementation TroveOperation

#pragma mark - Lifecycle

- (id)initWithURL:(NSURL *)url saveToFilePath:(NSString *)saveFilePath
{
    self = [super init];
    if (self) {
        _connectionURL = url;
        _filePath = saveFilePath;
        _stream = [[NSOutputStream alloc] initToFileAtPath:saveFilePath append:YES];
    }
    return self;
}

- (void)dealloc
{
    if (self.connection) {
        [self.connection cancel];
        self.connection = nil;
    }
    
    _connectionURL = nil;
    
    [_stream close];
    _stream = nil;
    _filePath = nil;
    _error = nil;
}

#pragma mark - Accessors

- (BOOL)isConcurrent
{
    return YES;
}

/*
 *  Return this instance's override for executing.
 */
- (BOOL)isExecuting
{
    return self.executing;
}

/*
 *  Return this instance's override for finished.
 */
- (BOOL)isFinished
{
    return self.finished;
}

#pragma mark - NSURLConnection handling

- (void)start
{
    if (![self isReady]) {
        // TODO: Throw exception?
        return;
    }
    
    if (self.finished || [self isCancelled]) {
        [self done];
    }
    
    // NSURLConnections must be executed on the main thread
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    [self setExecuting:YES];
    [self didChangeValueForKey:@"isExecuting"];

    // TODO: Determine length for timeout
    // TODO: Ensure the timeout count starts when the operations starts, and not when it's queued
    self.connection = [[NSURLConnection alloc] initWithRequest:
                       [NSURLRequest requestWithURL:self.connectionURL
                                        cachePolicy:NSURLRequestUseProtocolCachePolicy
                                    timeoutInterval:15.0f] delegate:self];
}

-(void)cancelled {
	// Code for being cancelled
    _error = [[NSError alloc] initWithDomain:@"TroveOperation"
                                        code:0
                                    userInfo:nil];
    [self.stream close];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:self.filePath error:NULL];
    
    [self done];
}

/*
 *  Close the connection and trigger KVO for observers that the operation is finihsed.
 */
- (void)done
{
    if (self.connection) {
        [self.connection cancel];
        self.connection = nil;
    }
    
    [self.stream close];
    self.stream = nil;
    
    // Alert anyone that we are finished
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.executing = NO;
    self.finished  = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

#pragma mark - NSURLConnectionDelegate Methods

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    if ([self isCancelled]) {
        [self cancelled];
		return;
    } else {
		_error = [error copy];
		[self done];
	}
}

#pragma mark - NSURLConnectionData Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([self isCancelled]) {
        [self cancelled];
        return;
    }
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger statusCode = [httpResponse statusCode];
    long long contentLength = [httpResponse expectedContentLength];
    NSString *currentURL = [[[connection currentRequest] URL] absoluteString];

    
    if (statusCode == 200 && contentLength > 0) {
        [self.stream open];
    } else {
        NSString* statusError = [NSString stringWithFormat:
                                 NSLocalizedString(@"URL String: %@, HTTP Code: %ld, Expected Content Length: %ld", nil),
                                 currentURL, statusCode, contentLength];
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:statusError forKey:NSLocalizedDescriptionKey];
        _error = [[NSError alloc] initWithDomain:@"TroveOperation"
                                            code:statusCode
                                        userInfo:userInfo];
        
        [self done];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ([self isCancelled]) {
        [self cancelled];
        return;
    }
    
    int bytesWritten = [self.stream write:[data bytes] maxLength:[data length]];
    
    if (bytesWritten < 0) {
        _error = [[NSError alloc] initWithDomain:@"TroveOperation"
                                            code:1
                                        userInfo:[NSDictionary dictionaryWithObject:@"Error writing to disk" forKey:NSLocalizedDescriptionKey]];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self isCancelled]) {
        [self cancelled];
        return;
    } else {
        [self done];
    }
}

// Return nil so object will NOT be stored in NSURLCache
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}


@end
