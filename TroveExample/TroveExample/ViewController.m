//
//  ViewController.m
//  TroveExample
//
//  Created by Mikhail Sinanan on 10/31/13.
//  Copyright (c) 2013 NPR. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()

@property (nonatomic, strong) NSString *sampleURL;
@property (nonatomic, strong) NSString *userAssetURL;
@property (nonatomic, strong) MPMoviePlayerController *player;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //allow keyboard to hide if touched outside the textfields
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.sampleURL = @"http://archive.org/download/American1956_4/American1956_4_512kb.mp4";
    
    //Add this observer so the 'done' button on the movie player will exit out of the video
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPressedDone)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object:Nil];
    
    // Hide the play video button until the video is downloaded
    self.playBtn.hidden = YES;
    self.viewPathBtn.hidden = YES;
    
    [self.activityView stopAnimating];
    [self.assetActivityView stopAnimating];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc {
    
    self.player = nil;
    self.sampleURL = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (IBAction)downloadSampleVideo:(id)sender {
    
    [[Trove sharedInstance] setDelegate:self];
    [[Trove sharedInstance] cacheAsset:[NSURL URLWithString:self.sampleURL]];
    
    [self.activityView startAnimating];
}

- (IBAction)playVideo:(id)sender {
    
    NSURL *videoOnDiskURL = [[Trove sharedInstance] assetURL:[NSURL URLWithString:self.sampleURL]];
    
    self.player = [[MPMoviePlayerController alloc] initWithContentURL:videoOnDiskURL];
    self.player.view.frame = self.view.bounds;
    self.player.controlStyle = MPMovieControlStyleFullscreen;
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview: self.player.view];
    
    [self.player prepareToPlay];
    [self.player play];

}

- (void) playerPressedDone {
    
    [self.player.view removeFromSuperview];
    self.player = nil;
}

#
# pragma mark - Trove Delegate Methods
#

- (void) assetDownloadSuccessful: (NSURL*)assetPath {
    
    // Check to see if the sample video is on disk
    NSURL *url = [[Trove sharedInstance] assetURL:[NSURL URLWithString:self.sampleURL]];

    // Performing this check to show appropriate UI for the sample video provided
    if ( [assetPath.absoluteString isEqualToString:url.absoluteString] ) {
        [self.activityView stopAnimating];
        
        // Show the play button since download was successful
        self.playBtn.hidden = NO;
        
    } else {
        
        // This will show the user entered asset paths,
        // if they are valid and downloaded successfully
        
        [self.assetActivityView stopAnimating];
        self.viewPathBtn.hidden = NO;
        
        // store the path so the UIAlertView can display it
        self.userAssetURL = assetPath.absoluteString;
    }
}

- (void)assetDownloadFailed:(NSError*)error {
    
    [self.activityView stopAnimating];
    [self.assetActivityView stopAnimating];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Trove Error"
                                                        message:@"Asset failed to download"
                                                       delegate:self
                                              cancelButtonTitle:Nil otherButtonTitles:@"OK",nil];
    [alertView show];
}

#
# pragma mark - UITextField Delegate Methods
#

- (void)dismissKeyboard {
    [self.assetTextField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if ( textField.text.length > 0 ) {
        
        // IMPORTANT: Make sure URL is valid and cache-control header allows the asset to be cached.
        // Example of a downloadble asset: Cache-Control = max-age=2000
        // Example of a NON-downloadable asset: Cache-Control = no-cache
        [[Trove sharedInstance] setDelegate:self];
        [[Trove sharedInstance] cacheAsset:[NSURL URLWithString:textField.text]];
        
        [self.assetActivityView startAnimating];
    }
}

- (IBAction)viewAssetSource:(id)sender {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Asset Path"
                                                        message:self.userAssetURL
                                                       delegate:self
                                              cancelButtonTitle:Nil otherButtonTitles:@"OK",nil];
    [alertView show];
}

@end
