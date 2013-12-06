Trove
=====

Trove is an iOS framework that provides an intelligent, transparent local cache of rich media web assets. 
You know, for those precious offline moments when users don't have Internet connectivity but just can't 
stop using your app. 

## Requirements 
- Foundation.framework
- Reachability.h (included in the example project and found [here](https://developer.apple.com/Library/ios/samplecode/Reachability/Introduction/Intro.html))
 
## Usage

#### Cache a media asset
```objective-c
NSString *sampleURL = @"http://foo.org/fooBar.mp4";
[[Trove sharedInstance] cacheAsset:[NSURL URLWithString:sampleURL]];
```
#### Retrieve a media asset
  This method will return the locally stored file URL, if it is not in the cache directory, the original asset URL will be returned.
```objective-c
NSString *sampleURL = @"http://foo.org/fooBar.mp4";
[[Trove sharedInstance] assetURL:[NSURL URLWithString:sampleURL]];
```
#### Optional delegate methods
```objective-c
- (void)assetDownloadSuccessful:(NSURL*)assetPath;
- (void)assetDownloadFailed;
```

## License

Code is licensed under [MIT License Terms](https://github.com/npr/trove/blob/master/LICENSE).
