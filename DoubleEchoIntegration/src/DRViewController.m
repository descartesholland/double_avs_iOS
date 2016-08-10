//
//  DRViewController.m
//  DoubleBasicHelloWorld
//
//  Created by David Cann on 8/3/13.
//  Copyright (c) 2013 Double Robotics, Inc. All rights reserved.
//

#import "DRViewController.h"
#import "DoubleControlSDK.h"

#import "DREchoHandler.h"
#import "DRAppDelegate.h"

@interface DRViewController () <DRDoubleDelegate, UIWebViewDelegate>
@end

@implementation DRViewController

//@synthesize accessTokenField;
@synthesize webView;
@synthesize emptyViewForWK;

DRDriveDirection currentDirection;
float currentTurn;


- (void)viewDidLoad {
    [super viewDidLoad];
    [DRDouble sharedDouble].delegate = self;
    NSLog(@"SDK Version: %@", kDoubleBasicSDKVersion);
    
    /*
     NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?client_id=%@&scope=%@&scope_data=%@&response_type=%@&redirect_uri=%@",
     [DREchoHandler sharedEchoHandler].AUTHENTICATION_ENDPOINT,
     [[DREchoHandler sharedEchoHandler].CLIENT_ID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
     [[DREchoHandler sharedEchoHandler].SCOPE stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
     [[DREchoHandler sharedEchoHandler].SCOPE_DATA stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
     [[DREchoHandler sharedEchoHandler].RESPONSE_TYPE stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
     [DREchoHandler sharedEchoHandler].REDIRECT_URI /*stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]*]];
     */
    //    NSURL *url = [NSURL URLWithString:[DREchoHandler sharedEchoHandler].AUTHENTICATION_ENDPOINT ];
    
    //    NSURLRequest *nsrequest=[NSURLRequest requestWithURL:url];
    webView = [[UIWebView alloc] initWithFrame:CGRectMake(30,500,300,500)];
    [webView setDelegate:self];
    //    [webView loadRequest:nsrequest];
    [self.view addSubview:webView];
    
    //    [[DREchoHandler sharedEchoHandler] init];
    
    
    /*
     NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:add ];
     [urlRequest setHTTPMethod:@"POST"];
     NSOperationQueue *queue = [[NSOperationQueue alloc] init];
     
     [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
     NSLog(@"openingURL");
     [[UIApplication sharedApplication] openURL:[response URL]];
     NSLog(@"handlingOpenURL");
     //                 [[[UIApplication sharedApplication] delegate] application:[UIApplication sharedApplication] handleOpenURL:[response URL]];
     }];*/
    
    //    [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    //     {
    //         NSLog(@"openingURL");
    //         [[UIApplication sharedApplication] openURL:[response URL]];
    //         NSLog(@"handlingOpenURL");
    //         [[[UIApplication sharedApplication] delegate] application:[UIApplication sharedApplication] handleOpenURL:[respons e URL]];
    //     }];
    
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (IBAction)startEchoHandler:(id)sender {
    
    NSLog(@"Starting Echo handler");
    
    DREchoHandler * handler = [DREchoHandler sharedEchoHandler];
    
}


- (IBAction)next {
    UIViewController * buddiesOrFacebook = [[UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil]   instantiateViewControllerWithIdentifier:@"loginController"] ;
    [self presentViewController:buddiesOrFacebook animated:YES completion:nil];
}

- (void) populateAccessToken : (NSString *) url {
    //    [self accessTokenField].text = url;
    //    accessTokenField.text = url;
}

#pragma mark - Actions
- (IBAction) submitAccessToken:(id)sender{
    NSArray * token = [accessTokenField.text componentsSeparatedByString:@"="];
    NSString * accessToken = [token[1] componentsSeparatedByString:@"&"][0];
    NSLog(@"access Token: %@", [accessToken stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
    [[DREchoHandler sharedEchoHandler] setAccessToken:[accessToken stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (IBAction)toggleMic:(id)sender {
    [[DREchoHandler sharedEchoHandler] audioSwitch];
}


- (IBAction)poleUp:(id)sender {
    [[DRDouble sharedDouble] poleUp];
}

- (IBAction)poleStop:(id)sender {
    [[DRDouble sharedDouble] poleStop];
}

- (IBAction)poleDown:(id)sender {
    [[DRDouble sharedDouble] poleDown];
}

- (IBAction)kickstandsRetract:(id)sender {
    [[DRDouble sharedDouble] retractKickstands];
}

- (IBAction)kickstandsDeploy:(id)sender {
    [[DRDouble sharedDouble] deployKickstands];
}

- (IBAction)startTravelData:(id)sender {
    [[DRDouble sharedDouble] startTravelData];
}

- (IBAction)stopTravelData:(id)sender {
    [[DRDouble sharedDouble] stopTravelData];
}

#pragma mark - DRDoubleDelegate

- (void)doubleDidConnect:(DRDouble *)theDouble {
    statusLabel.text = @"Double Connected";
}

- (void)doubleDidDisconnect:(DRDouble *)theDouble {
    statusLabel.text = @"Double Not Connected";
}

- (void)doubleStatusDidUpdate:(DRDouble *)theDouble {
    poleHeightPercentLabel.text = [NSString stringWithFormat:@"%f", [DRDouble sharedDouble].poleHeightPercent];
    kickstandStateLabel.text = [NSString stringWithFormat:@"%d", [DRDouble sharedDouble].kickstandState];
    batteryPercentLabel.text = [NSString stringWithFormat:@"%f", [DRDouble sharedDouble].batteryPercent];
    batteryIsFullyChargedLabel.text = [NSString stringWithFormat:@"%d", [DRDouble sharedDouble].batteryIsFullyCharged];
    firmwareVersionLabel.text = [DRDouble sharedDouble].firmwareVersion;
    serialLabel.text = [DRDouble sharedDouble].serial;
}

- (void)doubleDriveShouldUpdate:(DRDouble *)theDouble {
    NSLog(@"doubleDriveShouldUpdate");
    float drive = (driveForwardButton.highlighted) ? kDRDriveDirectionForward : ((driveBackwardButton.highlighted) ? kDRDriveDirectionBackward : kDRDriveDirectionStop);
    float turn = (driveRightButton.highlighted) ? 1.0 : ((driveLeftButton.highlighted) ? -1.0 : 0.0);
    
    if(drive == kDRDriveDirectionStop && currentDirection != kDRDriveDirectionStop) {
        NSLog(@"drive is not stop and current direction is set; driving ");
        drive = currentDirection;
    }
    if(turn == 0.0 && currentTurn != 0.0) {
        turn = currentTurn;
    }
    [theDouble drive:drive turn:turn];
}

- (void)doubleTravelDataDidUpdate:(DRDouble *)theDouble {
    leftEncoderLabel.text = [NSString stringWithFormat:@"%.02f", [leftEncoderLabel.text floatValue] + [DRDouble sharedDouble].leftEncoderDeltaInches];
    rightEncoderLabel.text = [NSString stringWithFormat:@"%.02f", [rightEncoderLabel.text floatValue] + [DRDouble sharedDouble].rightEncoderDeltaInches];
    NSLog(@"Left Encoder: %f, Right Encoder: %f", theDouble.leftEncoderDeltaInches, theDouble.rightEncoderDeltaInches);
}

- (void) sendWebViewURL : (NSURL*) url {
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void) webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad with url: %@", [[[(DRAppDelegate*) [[UIApplication sharedApplication] delegate ] viewController] webView].request mainDocumentURL]);
}

- (BOOL)webView:(UIWebView *)mWebView shouldStartLoadWithRequest:(NSURLRequest *)request          navigationType:(UIWebViewNavigationType)navigationType {
    
    if([request.URL fragment]) {
        //NSLog(@"Request URL Fragment:%@", [request.URL fragment]);
        NSArray *tokens = [[request.URL fragment] componentsSeparatedByString:@"&"];
        
        //Turn query parameters into dictionary
        NSMutableDictionary *queryParams=[[NSMutableDictionary alloc] init];
        
        for (int i = 0; i < [tokens count]; i++) {
            NSArray<NSString * > *  temp = [tokens[i] componentsSeparatedByString:@"="];
            [queryParams setObject:temp[1] forKey:temp[0]];
        }
        
        if([queryParams valueForKey:@"access_token"]) {
            
            NSString * accessToken = [queryParams valueForKey:@"access_token"];
            //NSLog(@"Access token: %@", accessToken);
            [[DREchoHandler sharedEchoHandler] setAccessToken:[accessToken stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if([queryParams valueForKey:@"code"]) {
            NSString * code = [queryParams valueForKey:@"code"];
            NSLog(@"Code: %@", code);
            NSLog(@"Requesting Access Token");
            
        }
    }
    return YES;
    
}

-(void) driveForward:(DRDriveDirection ) direction {
    if(direction != kDRDriveDirectionStop) {
        NSLog(@"Driving....");
        currentDirection = direction;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSLog(@"Stopping...");
            currentDirection = kDRDriveDirectionStop;
        });
    }
    
}

-(void) turn: (float) speed {
    NSLog(@"Turning....");
    currentTurn = speed;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSLog(@"Stopping...");
        currentTurn = 0;
    });
}
@end
