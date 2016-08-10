//
//  DREchoHandler.h
//  DoubleBasicHelloWorld
//
//  Created by Descartes Holland on 4/21/16.
//  Copyright © 2016 Double Robotics, Inc. All rights reserved.
//

//#import "AudioProcessor.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CFNetwork/CFNetwork.h>
#import "DRAudioController.h"

@interface DREchoHandler : NSObject {
    NSString * _accessToken;
    DREchoHandler * sharedHandler;
    DRAudioController * audioController;
}


@property (strong, nonatomic) NSArray *caChainArray;
@property (retain, nonatomic) NSString *AUTHENTICATION_ENDPOINT;
@property (retain, nonatomic) NSString *AVS_ENDPOINT;// = @"https://avs-alexa-na.amazon.com";
@property (retain, nonatomic) NSString *AVS_EVENTS_PATH;
@property (retain, nonatomic) NSString *AVS_DIRECTIVES_PATH;
@property (retain, nonatomic) NSString * CLIENT_ID;
@property (retain, nonatomic) NSString * SCOPE;
@property (retain, nonatomic) NSString * SCOPE_DATA;
@property (retain, nonatomic) NSString * RESPONSE_TYPE;
@property (retain, nonatomic) NSString * REDIRECT_URI;

@property (retain, nonatomic) NSString *AVS_TOKEN_RESPONSE_URL;// = @"https://api.amazon.com/auth/o2/token";

@property (retain, nonatomic) NSString *accessToken;

//@property (nonatomic, strong) DREchoHandler * sharedHandler;

@property (nonatomic,strong) NSURLSession *session;

//@property (strong, nonatomic) DRViewController *viewController;

//- (NSString *)stringForHTTPRequest;

+ (DREchoHandler*) sharedEchoHandler;

- (NSString *) getAccessToken;

- (void) setAccessToken : (NSString*) token;

// actions
- (IBAction)riseGain:(id)sender;
- (IBAction)lowerGain:(id)sender;


- (void)audioSwitch;

- (void) generateVoiceRequest:(NSData*) audioData;

- (void) synchronizeState;

- (void) establishDownchannel;

@end
