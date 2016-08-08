/**
 * Copyright 2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * You may not use this file except in compliance with the License. A copy of the License is located the "LICENSE.txt"
 * file accompanying this source. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the specific language governing permissions and limitations
 * under the License.
 */

#import <CommonCrypto/CommonDigest.h>

#import <LoginWithAmazon/LoginWithAmazon.h>
#import "LoginController.h"
#import "ProvisioningClient.h"

@interface LoginController()
    @property (strong, nonatomic) NSString *sessionId;
    @property (strong, nonatomic) NSString *productId;
    @property (strong, nonatomic) NSString *dsn;
    @property (strong, nonatomic) NSString *codeChallenge;
    @property (strong, nonatomic) NSString *authCode;
    @property (strong, nonatomic) ProvisioningClient* deviceProvisionClient;
@end

@implementation LoginController

- (NSData *)sha256:(NSData *)data {
    unsigned char hash[CC_SHA1_DIGEST_LENGTH];
    if ( CC_SHA256([data bytes], [data length], hash) ) {
        NSData *sha1 = [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
        return sha1;
    }
    return nil;
}

- (IBAction)onConnectButtonClicked:(id)sender {
    [self.deviceProvisionClient getDeviceProvisioningInfo: self.deviceAddress.text];
    self.loginButton.hidden = NO;
    self.deviceSearchProgress.hidden = NO;
    self.provisionSuccessText.hidden = YES;
    [self.deviceSearchProgress startAnimating];
    self.connectToDeviceButton.hidden = YES;
    
    [AIMobileLib clearAuthorizationState:nil];
}

- (void) errorSearchingForDevice: (NSError*) error {
    [[[UIAlertView alloc] initWithTitle:@"Searching Error"
                            message:[error localizedDescription]
                            delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil] show];
    [self showSearchPage];
}

- (void) errorProvisioningDevice: (NSError*) error {
    [[[UIAlertView alloc] initWithTitle:@"Provisioning Error"
                            message:[error localizedDescription]
                            delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil] show];
}

- (IBAction) onLogInButtonClicked:(id)sender {
    NSLog(@"log in button clicked");
    
//    NSData *dataIn = [@"fortyfour_fortyfour_fortyfour_fortyfour_four" dataUsingEncoding:NSASCIIStringEncoding];
//    NSMutableData *macOut = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];

//    CC_SHA256(dataIn.bytes, dataIn.length,  macOut.mutableBytes);

    
//    NSData * data = [@"fortyfour_fortyfour_fortyfour_fortyfour_four" dataUsingEncoding:NSUTF8StringEncoding];
//    unsigned char hash[CC_SHA1_DIGEST_LENGTH];
//    NSData *sha256 = [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
    
//    self.codeChallenge =  [sha256 base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)nil];
//    self.codeChallenge = [self.codeChallenge stringByReplacingOccurrencesOfString:@"=" withString:@""];
    
    NSLog(@"code Challenge: %@", self.codeChallenge);
    NSArray *requestScopes = @[@"alexa:all"];
    
    
    NSString* scopeData = [NSString stringWithFormat:@"{\"alexa:all\":{\"productID\":\"%@\","
                           "\"productInstanceAttributes\":{\"deviceSerialNumber\":\"%@\"}}}",
                           @"echo57", @"B0F00712527503CX"];
    
    NSDictionary *options = @{kAIOptionScopeData:scopeData,
                              kAIOptionReturnAuthCode:@YES,
                              kAIOptionCodeChallenge:self.codeChallenge,
                              kAIOptionCodeChallengeMethod:@"S256"};

    NSLog(@"authorizing user");
        [AIMobileLib authorizeUserForScopes:requestScopes delegate:self options:options];
//    [AIMobileLib authorizeUserForScopes:requestScopes delegate:[[LoginController alloc] init] options:options];
}


-(void) userSuccessfullySignedIn {
    NSLog(@"signed in successfully");
    self.loginButton.hidden = YES;
    NSLog(@"Posting, %@, %@, %@", self.deviceAddress.text, self.authCode, self.sessionId);
    [self.deviceProvisionClient postCompanionProvisioningInfo: self.deviceAddress.text: self.authCode : self.sessionId];
}

- (void) showSearchPage {
    NSLog(@"showing search page");
    self.deviceSearchProgress.hidden = YES;
    self.connectToDeviceButton.hidden = NO;
    self.loginButton.hidden = YES;
}



- (void) deviceDiscovered : (AVSDeviceResponse *) response {
    NSLog(@"device discovered, productId : %@, sessionId: %@", response.productId, response.sessionId);
    [self.deviceSearchProgress stopAnimating];
    self.deviceSearchProgress.hidden = YES;
    self.connectToDeviceButton.hidden = NO;
    self.loginButton.hidden = NO;
    self.sessionId = response.sessionId;
    self.productId = response.productId;
    self.dsn = response.dsn;
    self.codeChallenge = response.codeChallenge;
}

- (void) deviceSuccessfulyProvisioned {
    self.provisionSuccessText.hidden = NO;
}

#pragma mark Implementation of authorizeUserForScopes:delegate: delegates.
- (void)requestDidSucceed:(APIResult *)apiResult {
    NSLog(@"did succeed");
    // Fetch the authorization code and return to controller
    NSString* authorizationCode = apiResult.result;

    self.authCode = apiResult.result;
    NSLog(@"authorizationCode: %@", authorizationCode);
    [self userSuccessfullySignedIn];
    
}

- (void)requestDidFail:(APIError *)errorResponse {
    // Notify the user that authorization failed
    NSLog(@"did fail");
    [[[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"User authorization failed with message: %@", errorResponse.error.message] delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil] show];
}

#pragma mark View controller specific functions
- (BOOL)shouldAutorotate {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.deviceSearchProgress.hidden = YES;
    self.loginButton.hidden = YES;
    self.provisionSuccessText.hidden = YES;
    NSLog(@"setting device provisioning client");
    self.deviceProvisionClient = [[ProvisioningClient alloc] initWithDelegate:self];

    float systemVersion=[[[UIDevice currentDevice] systemVersion] floatValue];
    if(systemVersion>=7.0f)
    {
        CGRect tempRect;
        for(UIView *sub in [[self view] subviews])
        {
            tempRect = [sub frame];
            tempRect.origin.y += 20.0f; //Height of status bar
            [sub setFrame:tempRect];
        }
    }
}

@end
