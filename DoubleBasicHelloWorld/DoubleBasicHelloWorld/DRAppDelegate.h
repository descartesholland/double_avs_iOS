//
//  DRAppDelegate.h
//  DoubleBasicHelloWorld
//
//  Created by David Cann on 8/3/13.
//  Copyright (c) 2013 Double Robotics, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "DREchoHandler.h"
#import "DRViewController.h"

//#import "AWSCore.h"
//#import "AWSCognito.h"


@class DRViewController;

@interface DRAppDelegate : UIResponder <UIApplicationDelegate> {
    GCDWebServer* _webServer;
    //DRViewController* _viewController;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) DRViewController *viewController;



- (DRViewController*) viewController;
//- (NSString *)stringForHTTPRequest;

@end
