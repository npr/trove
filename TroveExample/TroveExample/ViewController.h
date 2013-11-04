//
//  ViewController.h
//  TroveExample
//
//  Created by Mikhail Sinanan on 10/31/13.
//  Copyright (c) 2013 NPR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Trove.h"

@interface ViewController : UIViewController <UITextFieldDelegate, TroveDelegate>


@property (nonatomic, strong) IBOutlet UIButton *downloadBtn;
@property (nonatomic, strong) IBOutlet UIButton *playBtn;
@property (nonatomic, strong) IBOutlet UIButton *viewPathBtn;
@property (nonatomic, strong) IBOutlet UITextField *assetTextField;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *assetActivityView;

- (IBAction)downloadSampleVideo:(id)sender;
- (IBAction)playVideo:(id)sender;
- (IBAction)viewAssetSource:(id)sender;

@end
