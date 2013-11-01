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
@property (nonatomic, strong) MPMoviePlayerController *player;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.sampleURL = @"http://archive.org/download/American1956_4/American1956_4_512kb.mp4";
    
    //Add this observer so the 'done' button on the movie player will exit out of the video
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPressedDone)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object:Nil];
    
    // Hide the play video button until the video is downloaded
    self.playBtn.hidden = YES;
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

- (IBAction)downloadSampleVide:(id)sender {
    
    [[Trove sharedInstance] setDelegate:self];
    [[Trove sharedInstance] cacheAsset:[NSURL URLWithString:self.sampleURL]];
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

- (void) assetDownloadSuccessful {
    
    // Show the play button since download was successful
    self.playBtn.hidden = NO;
    
}

@end
