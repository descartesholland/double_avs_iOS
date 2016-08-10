//
//  DRViewController.h
//  DoubleBasicHelloWorld
//
//  Created by David Cann on 8/3/13.
//  Copyright (c) 2013 Double Robotics, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AVS/AVSDeviceResponse.h"
#import "AVS/ProvisioningClient.h"
#import "DRDouble.h"

@interface DRViewController : UIViewController {
	IBOutlet UILabel *statusLabel;
	IBOutlet UILabel *poleHeightPercentLabel;
	IBOutlet UILabel *kickstandStateLabel;
	IBOutlet UILabel *batteryPercentLabel;
	IBOutlet UILabel *batteryIsFullyChargedLabel;
	IBOutlet UILabel *firmwareVersionLabel;
	IBOutlet UILabel *serialLabel;
	IBOutlet UILabel *leftEncoderLabel;
	IBOutlet UILabel *rightEncoderLabel;
	IBOutlet UIButton *driveForwardButton;
	IBOutlet UIButton *driveBackwardButton;
	IBOutlet UIButton *driveLeftButton;
	IBOutlet UIButton *driveRightButton;
    IBOutlet UIButton *submitButton;
    IBOutlet UISwitch *audioSwitch;
    IBOutlet UITextField *accessTokenField;
    IBOutlet UIWebView *webView;
    IBOutlet UIView *emptyViewForWK;
    
}

@property (nonatomic, retain) UITextField * accessTokenField;
@property (nonatomic, retain) UIWebView * webView;
@property (nonatomic, retain) UIView * emptyViewForWK;

- (void) sendWebViewURL : (NSURL *) urlString;

- (IBAction)next;

- (void) driveForward:(DRDriveDirection) direction;

- (void) turn:(float) speed;
@end
