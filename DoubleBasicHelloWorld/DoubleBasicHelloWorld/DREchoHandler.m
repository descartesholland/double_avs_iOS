//
//  DREchoHandler.m
//  DoubleBasicHelloWorld
//
//  Created by Descartes Holland on 4/21/16.
//  Copyright © 2016 Double Robotics, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DREchoHandler.h"
#import "DRAppDelegate.h"
#import "AudioProcessor.h"
#import "DRViewController.h"
#import "DRAudioController.h"

#import <CommonCrypto/CommonDigest.h>


@implementation DREchoHandler

//@synthesize audioProcessor;
//@synthesize accessToken = _accessToken;

//NSString *AVS_ENDPOINT = @"https://avs-alexa-na.amazon.com";
//NSString * AVS_TOKEN_RESPONSE_URL = @"https://api.amazon.com/auth/o2/token";
BOOL audioListening = NO;

static id sharedHandler;


+(void) initialize {
    NSAssert([DREchoHandler class] == self, @"initializing new singleton Echo handler");
    sharedHandler = [[super alloc] init];
}

-(id)init
{
    self = [super init];
    if(self)
    {
        self.AUTHENTICATION_ENDPOINT =@"https://www.amazon.com/ap/oa/";
        self.AVS_ENDPOINT = @"https://avs-alexa-na.amazon.com";
        self.AVS_EVENTS_PATH = @"/v20160207/events";
        self.AVS_DIRECTIVES_PATH = @"/v20160207/directives";
        self.AVS_TOKEN_RESPONSE_URL = @"https://api.amazon.com/auth/o2/token";
        
        self.CLIENT_ID = @"amzn1.application-oa2-client.ccde0cdc13f54c5488a444679a472959";
        self.SCOPE = @"alexa:all";
        self.SCOPE_DATA = @"{\"alexa:all\": {\"productID\": \"echo57\",\"productInstanceAttributes\": {\"deviceSerialNumber\": \"B0F00712526703DL\"}}}";
        self.RESPONSE_TYPE = @"token";
        self.REDIRECT_URI = /*@"https://localhost:8883/authresponse/";*/@"http://128.157.15.219:8883/authresponse/";
        
        self.session = [self createSession];
        _accessToken = [[NSString alloc] initWithFormat:@""];
        
        [self startAuthentication];
        
        audioController = [[DRAudioController alloc] init ];
    }
    return self;
}

-(void) startAuthentication {
    NSLog(@"starting authentication...");
    NSString* urlString = [NSString stringWithFormat:@"%@?client_id=%@&scope=%@&scope_data=%@&response_type=%@&redirect_uri=%@",
                           self.AUTHENTICATION_ENDPOINT,
                           [self.CLIENT_ID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
                           [self.SCOPE stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
                           [self.SCOPE_DATA stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
                           [self.RESPONSE_TYPE stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
                           self.REDIRECT_URI /*stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]*/];
    
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSLog(@"URL:%@", [url absoluteString]);
    
    [[[self session] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSURL * returnedUrl = [response URL];
        NSString * returnedUrlString = [url absoluteString];
        NSLog(@"Error code:%ld\nResponse URL:%@", [error code], returnedUrlString);
        if([returnedUrlString containsString:@"access_token"]) {
            NSLog(@"Access Token Detected.");
            [(DRAppDelegate*) [[UIApplication sharedApplication] delegate] viewController].accessTokenField.text = returnedUrlString;
        }
        else {
            NSLog(@"Calling openURL to proceed with LWA.");
            [[(DRAppDelegate*) [[UIApplication sharedApplication] delegate ] viewController] sendWebViewURL:returnedUrl];
        }
    }] resume];

}

- (NSString*) getAccessToken {
    return _accessToken;
}

- (void) setAccessToken:(NSString *)token {
    NSLog(@"Setting DREcho Access Token to %@", token);
    _accessToken = [NSMutableString stringWithString: token];
    
    [self establishDownchannel];
}

#pragma mark Gain control

// gain factor += 1
/*- (IBAction)riseGain:(id)sender {
    if (audioProcessor == nil) return;
    [audioProcessor setGain: [audioProcessor getGain]+1.0f];
    //    [self setGainLabelValue:[audioProcessor getGain]];
}*/

// gain factor -= 1
/*- (IBAction)lowerGain:(id)sender {
    if (audioProcessor == nil) return;
    [audioProcessor setGain: [audioProcessor getGain]-1.0f];
    //    [self setGainLabelValue:[audioProcessor getGain]];
}*/

/*
 Switchtes AudioUnit from AudioProcessor on and off.
 Checks if processor exists. If not it will initialized.
 
 Nevermind that indicator and label stuff. I like it a bit fancy ;)
 */

- (void)audioSwitch {
    
    if (audioListening) {
//        NSLog(@"data? : %@", [audioProcessor audioBuffer].mData);
//        [self generateVoiceRequest: (__bridge NSData *)([audioProcessor audioBuffer].mData)];
        NSLog(@"Stopping AudioUnit");
        //[audioProcessor stop];
        [audioController stopRecording];
        NSLog(@"AudioUnit stopped");
        audioListening = false;
        
//                [audioProcessor audioBuffer] ;
//        audioController getRecorded
//        NSData* data = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"hello" ofType:@"wav"]];

        
    
    } else {
        if (audioController == nil) {
            audioController = [[DRAudioController alloc] init];
        }
        NSLog(@"Starting up AudioUnit");
//        [audioProcessor start];
        [audioController startRecording];
        NSLog(@"AudioUnit running");
        audioListening = true;
    }
    //    [self performSelector:@selector(showLabelWithText:) withObject:@"" afterDelay:3.5];
}

+ (instancetype) sharedEchoHandler {
    return sharedHandler;
}

- (void) establishDownchannel {
    NSLog(@"Establishing Downchannel.");
    
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"ca" ofType:@"der"];
    NSLog(@"cerPath: %@", cerPath);
    NSData *derCA = [NSData dataWithContentsOfFile:cerPath];
    SecCertificateRef caRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)derCA);
    self.caChainArray = [NSArray arrayWithObject:(__bridge id)(caRef)];
    CFRelease(caRef);
    
    
    NSString *boundary = @"IoT";
    
    
    NSMutableURLRequest *getReq = [NSMutableURLRequest requestWithURL:[[NSURL alloc] initWithString: [NSString stringWithFormat:@"%@%@", self.AVS_ENDPOINT, self.AVS_DIRECTIVES_PATH ]]];
    [getReq setHTTPMethod:@"GET"];
    [getReq setValue:[NSString stringWithFormat: @"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    [getReq setValue:[NSString stringWithFormat:@"Bearer %@", _accessToken] forHTTPHeaderField:@"authorization"];
    
    
    NSLog(@"%@",[getReq allHTTPHeaderFields]);
    
    /////////////////////////////////////////////////
    
    NSURLSessionConfiguration * config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"downchannel"];
    NSTimeInterval interval = 10000;
    [config setTimeoutIntervalForRequest:interval];
    [config setHTTPMaximumConnectionsPerHost:3];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:getReq ];
  /*                                          completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                    NSLog(@"Response URL: %@", [response URL]);
                                      NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                      NSLog(@"Response body: %@", responseBody);
                                      NSLog(@"Error: %ld", (long)[error code]);
                                      
                                  }];*/
    [task resume];
    
    [self synchronizeState];
    
}

- (NSDictionary *) getPlaybackState {
    
    NSLog(@"Getting playback state.");
    NSDictionary * header = [[NSDictionary alloc] initWithObjects:
                             [[NSArray alloc] initWithObjects:@"AudioPlayer", @"PlaybackState", nil] forKeys:
                             [[NSArray alloc] initWithObjects: @"namespace", @"name", nil]];
    
    NSDictionary * payload = [[NSDictionary alloc] initWithObjects:
                              [[NSArray alloc] initWithObjects:@"", @0, @"IDLE", nil] forKeys:
                              [[NSArray alloc] initWithObjects:@"token", @"offsetInMilliseconds", @"playerActivity", nil]];
    
    NSDictionary * state = [[NSDictionary alloc] initWithObjects:
                            [[NSArray alloc] initWithObjects: header, payload, nil ] forKeys:
                            [[NSArray alloc] initWithObjects: @"header", @"payload", nil]];
    
    return state;
}

- (NSDictionary *) getAlertState {
    
    NSLog(@"Getting alert state.");
    NSDictionary * header = [[NSDictionary alloc] initWithObjects:
                             [[NSArray alloc] initWithObjects:@"Alerts", @"AlertsState", nil] forKeys:
                             [[NSArray alloc] initWithObjects: @"namespace", @"name", nil]];
    
    NSDictionary * payload = [[NSDictionary alloc] initWithObjects:
                              [[NSArray alloc] initWithObjects:[[NSArray alloc] init],[[NSArray alloc] init], nil] forKeys:
                              [[NSArray alloc] initWithObjects:@"allAlerts", @"activeAlerts", nil]];
    
    NSDictionary * state = [[NSDictionary alloc] initWithObjects:
                            [[NSArray alloc] initWithObjects: header, payload, nil ] forKeys:
                            [[NSArray alloc] initWithObjects: @"header", @"payload", nil]];
    
    return state;
}

- (NSDictionary *) getVolumeState {
    
    NSLog(@"Getting volume state.");
    NSDictionary * header = [[NSDictionary alloc] initWithObjects:
                             [[NSArray alloc] initWithObjects:@"Speaker", @"VolumeState", nil] forKeys:
                             [[NSArray alloc] initWithObjects: @"namespace", @"name", nil]];
    
    NSDictionary * payload = [[NSDictionary alloc] initWithObjects:
                              [[NSArray alloc] initWithObjects:@75, @false, nil] forKeys:
                              [[NSArray alloc] initWithObjects:@"volume", @"muted", nil]];
    
    NSDictionary * state = [[NSDictionary alloc] initWithObjects:
                            [[NSArray alloc] initWithObjects: header, payload, nil ] forKeys:
                            [[NSArray alloc] initWithObjects: @"header", @"payload", nil]];
    
    return state;
}

- (NSDictionary *) getSpeechState {
    
    NSLog(@"Getting speech state.");
    NSDictionary * header = [[NSDictionary alloc] initWithObjects:
                             [[NSArray alloc] initWithObjects:@"SpeechSynthesizer", @"SpeechState", nil] forKeys:
                             [[NSArray alloc] initWithObjects: @"namespace", @"name", nil]];
    
    NSDictionary * payload = [[NSDictionary alloc] initWithObjects:
                              [[NSArray alloc] initWithObjects:@"", @0, @"FINISHED", nil] forKeys:
                              [[NSArray alloc] initWithObjects:@"token", @"offsetInMilliseconds", @"playerActivity", nil]];
    
    NSDictionary * state = [[NSDictionary alloc] initWithObjects:
                            [[NSArray alloc] initWithObjects:header, payload, nil ] forKeys:
                            [[NSArray alloc] initWithObjects: @"header", @"payload", nil]];
    
    return state;
}


- (NSArray *) getContext {
    NSLog(@"Getting Context.");
    NSArray * contexts = [[NSArray alloc] initWithObjects: [self getPlaybackState], [self getAlertState], [self getVolumeState], [self getSpeechState], nil];
    
    return contexts;
    
}

- (void) synchronizeState {
    NSLog(@"Synchronizing state");
    
    NSString *boundary = @"IoT";
    
    NSMutableURLRequest *postReq = [NSMutableURLRequest requestWithURL:[[NSURL alloc] initWithString: [NSString stringWithFormat:@"%@%@", self.AVS_ENDPOINT, self.AVS_EVENTS_PATH ]]];
    [postReq setHTTPMethod:@"POST"];
    [postReq setValue:[NSString stringWithFormat: @"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    [postReq setValue:[NSString stringWithFormat:@"Bearer %@", _accessToken]forHTTPHeaderField:@"authorization"];
    
    
    NSDictionary * header = [NSDictionary dictionaryWithObjectsAndKeys: @"System",           @"namespace",
                             @"SynchronizeState", @"name",
                             @"test",             @"messageId", nil];
    NSDictionary *jsonDict = [NSDictionary
                              dictionaryWithObjectsAndKeys:[self getContext], @"context",
                              [NSDictionary dictionaryWithObjectsAndKeys: header, @"header", @"", @"payload", nil], @"event", nil];
    
    NSData* jsonPayload = [NSJSONSerialization dataWithJSONObject:jsonDict options:kNilOptions error:nil];
    
    
    // post body
    NSMutableData *body = [NSMutableData data];
    
    // add params (all params are strings)
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@\r\n\r\n", @"\"metadata\""] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", @"application/json; charset=UTF-8"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:jsonPayload];
    
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:postReq queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        NSLog(@"response URL:%@\nStatus code:%ld\nHeaders:%@", [response URL], (long)[httpResponse statusCode], [httpResponse allHeaderFields]);

        NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Response body: %@", responseBody);
        NSLog(@"Error: %@\nCode:%ld", [error localizedDescription], (long) [error code]);
     }];
    
    
} 

///////////////////////////////

- (void) generateVoiceRequest: (NSData*) audioData {
    NSLog(@"Generating voice request");
    if([audioData length] > 0)
        NSLog(@"Audio Data detected.");
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString: [NSString stringWithFormat: @"%@%@", self.AVS_ENDPOINT, self.AVS_EVENTS_PATH]]];
    
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:60];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"IoT";
    
    // set Content-Type in HTTP header
    NSString *contentType = [NSString stringWithFormat:@"multipart/mixed; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", _accessToken]forHTTPHeaderField:@"authorization"];
    
    //Generate SpeechRecognizer intent message
    NSDictionary * eventHeaderDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"SpeechRecognizer",        @"namespace",
                                      @"Recognize",               @"name",
                                      @"TEST_ICICLE",             @"messageId",
                                      @"DLG",                     @"dialogRequestId", nil];
    
    NSDictionary * eventPayloadDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"CLOSE_TALK",                      @"profile",
                                       @"AUDIO_L16_RATE_16000_CHANNELS_1", @"format", nil];
    
    NSDictionary *messageJsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [self getContext],                                  @"context",
                                     [NSDictionary dictionaryWithObjectsAndKeys:
                                      eventHeaderDict,      @"header",
                                      eventPayloadDict,     @"payload", nil], @"event", nil];
    
    NSData* messageJsonData = [NSJSONSerialization dataWithJSONObject:messageJsonDict options:kNilOptions error:nil];
    
    
    // create body
    NSMutableData *body = [NSMutableData data];
    
    //Add context, event
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@\r\n", @"\"metadata\""] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"application/json; charset=UTF-8"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:messageJsonData];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // add binary audio attachment
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@\r\n", @"audio"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData: [[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"application/octet-stream"] dataUsingEncoding:NSUTF8StringEncoding]];
   
    [body appendData:audioData];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    // setting the body of the post to the reqeust
    [request setHTTPBody:body];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"error = %@", error);
        
        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"result data: %@", result);
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        
        NSLog(@"response URL:%@\nresponse status code:%ld", [response URL], (long)[httpResponse statusCode]);
    }];
    [task resume];

}

- (NSData *)sha256:(NSData *)data {
    unsigned char hash[CC_SHA1_DIGEST_LENGTH];
    if ( CC_SHA256([data bytes], [data length], hash) ) {
        NSData *sha1 = [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
        return sha1;
    }
    return nil;
}


- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    NSLog(@"session did receive challenge");
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        //        if ([trustedHosts containsObject:challenge.protectionSpace.host])
        NSLog(@"equal; using credentials");
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    //    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *) task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    NSLog(@"in here task");
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        //        if ([trustedHosts containsObject:challenge.protectionSpace.host])
        NSLog(@"equal; using credentials");
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    //    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}


- (NSURLSession *)createSession {
    static NSURLSession *session = nil;
    session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                            delegate:self
                                       delegateQueue:[NSOperationQueue mainQueue]];
    NSLog(@"Returning newly-created session");
    return session;
}


@end