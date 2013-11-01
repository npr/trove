//
//  ViewController.m
//  TroveExample
//
//  Created by Mikhail Sinanan on 10/31/13.
//  Copyright (c) 2013 NPR. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) NSString *sampleURL;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.sampleURL = @"http://commondatastorage.googleapis.com/gtv-videos-bucket/big_buck_bunny_1080p.mp4";
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
