//
//  DRAppDelegate.m
//  DoubleBasicHelloWorld
//
//  Created by David Cann on 8/3/13.
//  Copyright (c) 2013 Double Robotics, Inc. All rights reserved.
//

#import "DRAppDelegate.h"
#import "DRViewController.h"
#import "DREchoHandler.h"
#import "DRDouble.h"

#import <Security/Security.h>
#import <CoreFoundation/CoreFoundation.h>


#import "HTTP/HTTPServer.h"

#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerURLEncodedFormRequest.h"

#import <AWSCore/AWSCore.h>
#import <AWSCognito/AWSCognito.h>
#import <AWSIoT/AWSIoT.h>
#import <AWSIoT/AWSIoTKeychain.h>
#import <AWSIoT/AWSIoTMQTTClient.h>

@implementation DRAppDelegate

@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Override point for customization after application launch.
    self.viewController = [[DRViewController alloc] initWithNibName:@"DRViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    //setup logging
    [AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
    
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:AWSRegionUSEast1 identityPoolId:@"us-east-1:b58db775-cdeb-4a0e-a059-88c1a60262c3"];
    
    
    
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1
                                                                         credentialsProvider:credentialsProvider];
    
    
    [configuration setBaseURL:[[NSURL alloc] initWithString: @"ah8f61ur6juzh.iot.us-east-1.amazonaws.com/"]];
    NSLog(@"Endpoint: %@ \n %@", [configuration endpoint], [configuration baseURL]);
    
    
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
    
    //    NSData *certData = [[NSData alloc]
    //                        initWithContentsOfFile:[[NSBundle mainBundle]
    //                                                pathForResource:@"newCert" ofType:@"p12"]];
    
    [AWSIoTDataManager registerIoTDataManagerWithConfiguration:configuration forKey:@"USEast1IoTDataManager" ];
    //    [AWSIoTManager importIdentityFromPKCS12Data:certData passPhrase:@"flymetothemoon" certificateId:@"7f3d85afc72462c15a49a783054ab3deca3fea3c4dd049bbf63a9fce3eecf2bb"];
    //    [AWSIoTManager importIdentityFromPKCS12Data:certData passPhrase:@"flymetothemoon" certificateId:@"5705b3b89f"];
    [AWSIoTManager registerIoTManagerWithConfiguration:configuration forKey:@"USEast1IoTManager"];
    
    //    AWSIoTMQTTConfiguration *mqttConfiguration = [[AWSIoTMQTTConfiguration alloc] init];
    
    AWSIoTManager *iotManager = [AWSIoTManager IoTManagerForKey:@"USEast1IoTManager"];
    
    
    ////Add to keychain
    NSString *thePath = [[NSBundle mainBundle] pathForResource:@"newCert" ofType:@"p12"];
    NSData *PKCS12Data = [[NSData alloc] initWithContentsOfFile:thePath];
    
    
    [AWSIoTManager importIdentityFromPKCS12Data:PKCS12Data passPhrase:@"flymetothemoon" certificateId:@"ee996c9d2e55158464cacc6d900f2b37668ed9a3023cee065c04fce23e2dc621"];
    
    AWSIoTDataManager *iotDataManager = [AWSIoTDataManager IoTDataManagerForKey:@"USEast1IoTDataManager"];
    
    CFDataRef inPKCS12Data = (__bridge CFDataRef)PKCS12Data;
    SecIdentityRef identity;
    
    // extract the ideneity from the certificate
    [self extractIdentity :inPKCS12Data :&identity];
    
    SecCertificateRef certificate = NULL;
    SecIdentityCopyCertificate (identity, &certificate);
    //
    //
    //    [self persistentRefForIdentity:identity];
    
    //    [AWSIoTKeychain getIdentityRef:@"5705b3b89f"];
    
    [AWSIoTKeychain addCertificateRef : certificate]; ////////////////////
    
    //     [iotManager createKeysAndCertificateFromCsr:[[NSDictionary alloc] initWithObjects:[[NSArray alloc] initWithObjects:@"58fd7bea4664a218f3f79aafc10c8584846c94b9acc0075fe4274fecbafdb4c5",
    //     @"US", @"NASA", @"IoT", nil]
    //     forKeys:[[NSArray alloc] initWithObjects: @"commonName", @"countryName", @"organizationName", @"organizationalUnitName", nil ] ]
    //     callback:^(AWSIoTCreateCertificateResponse *mainResponse) {
    //     NSLog(@"AWSIoTCreateCertResponse ");
    //     NSLog(@"ARN:%@ \nID:%@ \nPEM:%@", [mainResponse certificateArn ], [mainResponse certificateId], [mainResponse certificatePem]);
    
    NSLog(@"Connecting...");
    bool b = [iotDataManager  connectUsingWebSocketWithClientId:@"testClientId" cleanSession:true statusCallback:^(AWSIoTMQTTStatus status) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //Here is the non-main thread.
            [NSThread sleepForTimeInterval:3.0f];
            NSLog(@"Subscribing...");
            [iotDataManager subscribeToTopic:@"double" QoS:AWSIoTMQTTQoSMessageDeliveryAttemptedAtLeastOnce messageCallback:^(NSData *data) {
                NSString* dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"MQTT Message received: %@", dataString);
                
                if([dataString isEqualToString:@"\"forward\""]  ||
                   [dataString isEqualToString:@"\"forwards\""]) {
                    NSLog(@"Driving forward. %@", [DRDouble sharedDouble].delegate);
                    [[self viewController] driveForward:kDRDriveDirectionForward];
                }
                
                if([dataString isEqualToString:@"\"backward\""]  ||
                   [dataString isEqualToString:@"\"backwards\""]) {
                    [[self viewController] driveForward:kDRDriveDirectionBackward];
                }
                if([dataString isEqualToString:@"nowhere"] || [dataString isEqualToString:@"stop"] || [dataString isEqualToString:@"\"nowhere\""] || [dataString isEqualToString:@"\"stop\""]) {
                    [[self viewController] driveForward:kDRDriveDirectionStop];
                    [[self viewController] turn:0];
                }
                
                
                if([dataString isEqualToString:@"\"left\""]) {
                    NSLog(@"Turning left. %@", [DRDouble sharedDouble].delegate);
                    [[self viewController] turn:-1];
                }
                if([dataString isEqualToString:@"\"right\""]) {
                    NSLog(@"Turning right. %@", [DRDouble sharedDouble].delegate);
                    [[self viewController] turn:1];
                }
            }];
            //            dispatch_async(dispatch_get_main_queue(), ^{
            //                //Here you return to main thread.
            //
            //
        });
        
        /*dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //Here your non-main thread.
            [NSThread sleepForTimeInterval:5.0f];
            dispatch_async(dispatch_get_main_queue(), ^{
                //Here you returns to main thread.
                NSLog(@"publishing...");
                [iotDataManager publishString:@"test" onTopic:@"topicTest" QoS:AWSIoTMQTTQoSMessageDeliveryAttemptedAtLeastOnce ];
            });
        });*/
        
        
    }];
    
    /*bool b = [iotDataManager connectWithClientId:@"default_CLIENT_ID" cleanSession:true certificateId:   @"ee996c9d2e55158464cacc6d900f2b37668ed9a3023cee065c04fce23e2dc621"/*@"5705b3b89f"* statusCallback:^(AWSIoTMQTTStatus status) {
     NSLog(@"MQTT status: %ld", status);
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
     //Here is the non-main thread.
     [NSThread sleepForTimeInterval:3.0f];
     NSLog(@"Subscribing...");
     [iotDataManager subscribeToTopic:@"topicTest" QoS:AWSIoTMQTTQoSMessageDeliveryAttemptedAtLeastOnce messageCallback:^(NSData *data) {
     NSLog(@"subscribe result data: %@", data);
     }];
     //            dispatch_async(dispatch_get_main_queue(), ^{
     //                //Here you return to main thread.
     //
     //
     //            });
     });
     }];
    NSLog(@"Connected? %d", b);
    
    //     }];
    
    
    
    
    
    /*
     
     NSString *thePath = [[NSBundle mainBundle] pathForResource:@"5705b3b89f" ofType:@"p12"];
     NSData *PKCS12Data = [[NSData alloc] initWithContentsOfFile:thePath];
     
     CFDataRef inPKCS12Data = (__bridge CFDataRef)PKCS12Data;
     SecIdentityRef identity;
     
     // extract the ideneity from the certificate
     [self extractIdentity :inPKCS12Data :&identity];
     
     SecCertificateRef certificate = NULL;
     SecIdentityCopyCertificate (identity, &certificate);
     
     //    [AWSIoTKeychain addCertificateRef : certificate]; ////////////////////
     
     NSString *pathPrivate = [[NSBundle mainBundle] pathForResource:@"5705b3b89f-private.pem" ofType:@"key"];
     NSData *privateKeyData = [[NSData alloc] initWithContentsOfFile:pathPrivate];
     [AWSIoTKeychain addPrivateKey:[[NSData alloc] initWithContentsOfFile:pathPrivate] tag:@"5705b3b89f-private"]; //////////////
     
     NSString *pathPublic = [[NSBundle mainBundle] pathForResource:@"5705b3b89f-public.pem" ofType:@"key"];
     [AWSIoTKeychain addPublicKey:[[NSData alloc] initWithContentsOfFile:pathPublic] tag:@"5705b3b89f-public"]; //////////////////
     
     NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
     [query setObject:(id)kSecClassKey forKey:(id)kSecClass];
     [query setObject:(id)kSecAttrAccessibleWhenUnlocked forKey:(id)kSecAttrAccessible];
     [query setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnData];
     
     //adding access key
     [query setObject:(id)@"flymetothemoon" forKey:(id)kSecAttrApplicationTag];
     
     
     //removing item if it exists
     SecItemDelete((CFDictionaryRef)query);
     
     //setting data (private key)
     [query setObject:(id)privateKeyData forKey:(id)kSecValueData];
     
     CFTypeRef persistKey; OSStatus status = SecItemAdd((CFDictionaryRef)query, &persistKey);
     
     if(status) {
     NSLog(@"Keychain error occured: %ld (statuscode)", status);
     return NO;
     }
     
     [AWSIoTKeychain addCertificateFromPemFile:@"5705b3b89f-certificate.pem.crt" withTag:@"5705b3b89f-cert"]; /////////////////////
     //    [AWSIoTKeychain addPrivateKey:privateKeyData tag:@"5705b3b89f" ];
     //    [AWSIoTKeychain addPublicKey:]
     /*
     const void *certs[] = {certificate};
     CFArrayRef certArray = CFArrayCreate(kCFAllocatorDefault, certs, 1, NULL);
     */
    
    //    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest2
    //                                                                         credentialsProvider:credentialsProvider];
    
    //    [AWSIoTManager registerIoTManagerWithConfiguration:configuration forKey:@"USWest2IoTManager"];
    
    //     AWSIoTManager *IoTManager = [AWSIoTManager IoTManagerForKey:@"USWest2IoTManager"];
    
    
    
    /*AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:AWSRegionUSEast1 identityPoolId:@"us-east-1_yAubvyPrb"];
     AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];*/
    
    //    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    //[AWSIoTDataManager registerIoTDataManagerWithConfiguration:configuration forKey:@"USEast1IoTDataManager"];
    
    
    //    NSData *certData = [[NSData alloc]
    //                        initWithContentsOfFile:[[NSBundle mainBundle]
    //                                                pathForResource:@"66558ee0a0" ofType:@"p12"]];
    //    [AWSIoTManager importIdentityFromPKCS12Data:certData passPhrase:@"flymetothemoon" certificateId:@"5705b3b89f"];
    
    
    //    [AWSIoTManager registerIoTManagerWithConfiguration:configuration forKey:@"USEast1IoTManager"];
    
    //    AWSIoTDataManager *dataManager = [AWSIoTDataManager IoTDataManagerForKey:@"USEast1IoTDataManager"];
    //    AWSIoTMQTTConfiguration *mqttConfiguration = [[AWSIoTMQTTConfiguration alloc] init];
    
    
    //    SecKeyRef *keyRef = [self getPublicKeyRef];
    
    //    NSString *path = [[NSBundle bundleForClass:[self class]]
    //                      pathForResource:@"5705b3b89f" ofType:@"p12"];
    //    NSData *p12data = [NSData dataWithContentsOfFile:path];
    //    if (![self getPrivateKeyRef])
    //    SecKeyRef *keyRef2 = getPrivateKeywithRawKey(p12data);
    
    /*NSLog(@"getting id ref & adding to keychain");
     
     NSString * password = @"flymetothemoon";
     NSString * path = [[NSBundle mainBundle]
     pathForResource:@"5705b3b89f" ofType:@"p12"];
     
     // prepare password
     CFStringRef cfPassword = CFStringCreateWithCString(NULL,
     password.UTF8String,
     kCFStringEncodingUTF8);
     const void *keys[]   = { kSecImportExportPassphrase };
     const void *values[] = { cfPassword };
     CFDictionaryRef optionsDictionary
     = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1,
     NULL, NULL);
     
     // prepare p12 file content
     NSData * fileContent = [[NSData alloc] initWithContentsOfFile:path];
     CFDataRef cfDataOfFileContent = (__bridge CFDataRef)fileContent;
     
     // extract p12 file content into items (array)
     CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
     OSStatus status3 = errSecSuccess;
     status3 = SecPKCS12Import(cfDataOfFileContent,
     optionsDictionary,
     &items);
     if(status3) {
     NSLog(@"Keychain idref error occured: %ld (statuscode)", status3);
     }
     
     
     // extract identity
     CFDictionaryRef yourIdentityAndTrust = CFArrayGetValueAtIndex(items, 0);
     const void *tempIdentity = NULL;
     tempIdentity = CFDictionaryGetValue(yourIdentityAndTrust,
     kSecImportItemIdentity);
     
     SecIdentityRef yourIdentity = (SecIdentityRef)tempIdentity;
     
     
     // get certificate from identity
     SecCertificateRef yourCertificate = NULL;
     status = SecIdentityCopyCertificate(yourIdentity, &yourCertificate);
     
     
     // at last, install certificate into keychain
     const void *keys2[]   = {    kSecValueRef,             kSecClass };
     const void *values2[] = { yourCertificate,  kSecClassCertificate };
     CFDictionaryRef dict
     = CFDictionaryCreate(kCFAllocatorDefault, keys2, values2,
     2, NULL, NULL);
     status = SecItemAdd(dict, NULL);
     
     // TODO: error handling on status
     
     NSLog(@"Adding cert to AWS keychain");
     
     NSMutableDictionary *secIdentityParams = [[NSMutableDictionary alloc] init];
     [secIdentityParams setObject:(__bridge id)yourIdentity forKey:(id)kSecValueRef];
     OSStatus status2 = SecItemAdd((CFDictionaryRef) secIdentityParams, NULL);
     if(status2) {
     NSLog(@"secIdentity error occured: %ld (statuscode)", status2);
     }
     
     NSString *derPath = [[NSBundle mainBundle] pathForResource:@"5705b3b89f" ofType:@"der"];
     NSData *derData = [[NSData alloc] initWithContentsOfFile:derPath];
     //    [AWSIoTKeychain addCertificateToKeychain:@"5705b3b89f.der"];
     
     
     [AWSIoTKeychain addCertificate:derData withTag:@"5705b3b89f"];
     
     [dataManager /*[AWSIoTDataManager defaultIoTDataManager] * connectWithClientId:@"DefaultClientId123" cleanSession:true certificateId:@"5705b3b89f" statusCallback:^(AWSIoTMQTTStatus status) {
     NSLog(@"AWSIotMQTTStatus:%ld", (long)status);
     }];
     
     */
    
    
    // Create server
    _webServer = [[GCDWebServer alloc] init];
    
    [_webServer addHandlerForMethod:@"GET" pathRegex:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        NSLog(@"HANDLER: /*");
        
        
        //Grab query parameters for drive direction
        NSMutableDictionary *queryParams = [[NSMutableDictionary alloc] init];
        for (NSString *param in [[[request URL] query] componentsSeparatedByString:@"&"]) {
            NSArray *elts = [param componentsSeparatedByString:@"="];
            if([elts count] < 2) continue;
            [queryParams setObject:[elts lastObject] forKey:[elts firstObject]];
        }
        
        NSLog(@"Gathered query parameters: %@", queryParams);
        
        
        GCDWebServerResponse* response = [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Hello World</p></body></html>"];
        [response setStatusCode:200];
        return response;
        //        return [[GCDWebServerResponse alloc] initWithStatusCode:(NSInteger) @200];
        
    }];

    
    [_webServer addHandlerForMethod:@"GET" pathRegex:@"/drive/*" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        NSLog(@"HANDLER: /drive/*");
        
        
        //Grab query parameters for drive direction
        NSMutableDictionary *queryParams = [[NSMutableDictionary alloc] init];
        for (NSString *param in [[[request URL] query] componentsSeparatedByString:@"&"]) {
            NSArray *elts = [param componentsSeparatedByString:@"="];
            if([elts count] < 2) continue;
            [queryParams setObject:[elts lastObject] forKey:[elts firstObject]];
        }
        
        NSLog(@"Gathered query parameters: %@", queryParams);
        
        
        GCDWebServerResponse* response = [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Hello World</p></body></html>"];
        [response setStatusCode:200];
        return response;
//        return [[GCDWebServerResponse alloc] initWithStatusCode:(NSInteger) @200];
        
    }];
    
    [_webServer addHandlerForMethod:@"GET" pathRegex:@"/authresponse/*" requestClass:[GCDWebServerRequest class]
                       processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                           NSLog(@"HANDLER: /authresponse/");
                           
                           NSLog(@"URL: %@ || %@", [[request URL] absoluteString], [[request URL] fragment]);
                           
                           NSArray *tokens = [[[request URL] fragment] componentsSeparatedByString:@"&"];
                           
                           //Turn query parameters into dictionary
                           NSMutableDictionary *queryParams=[[NSMutableDictionary alloc] init];
                           
                           for (int i = 0; i < [tokens count]; i++) {
                               NSArray<NSString * > *  temp = [tokens[i] componentsSeparatedByString:@"="];
                               [queryParams setObject:temp[1] forKey:temp[2]];
                           }
                           
                           NSLog(@"Gathered fragment parameters: %@", queryParams);
                           
                           
                           if([queryParams valueForKey:@"access_token"]) {
                               NSLog(@"Collected Access Token:%@", [queryParams valueForKey:@"access_token"]);
                               
                               NSString * accessToken = [[[request URL] fragment] valueForKey:@"access_token"]; //[[request query] valueForKey:@"access_token"];
                               NSLog(@"Access token: %@", accessToken);
                               [[DREchoHandler sharedEchoHandler] setAccessToken : accessToken];
                           }
                           else if([[request query] valueForKey:@"code"]) {
                               NSString * code = [[request query] valueForKey:@"code"];
                               NSLog(@"Code: %@", code);
                               NSLog(@"Requesting Access Token");
                               
                           }
                           
                           GCDWebServerResponse* test = [[GCDWebServerResponse alloc] initWithStatusCode:(NSInteger) @200];
                           
                           return test;
                           
                       }];
    
    //Start web server
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    [options setObject:[NSNumber numberWithInteger:8883] forKey:GCDWebServerOption_Port];
    [options setValue:nil forKey:GCDWebServerOption_BonjourName];
    [options setObject:@NO forKey:GCDWebServerOption_AutomaticallySuspendInBackground];
    [_webServer startWithOptions:options error:NULL];
    
    NSLog(@"Visit %@ in your web browser", _webServer.serverURL);
    
    return @YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url : (NSDictionary<NSString *, id> *)options {
    NSLog(@"openURL not implemented heh");
    NSLog(@"%@", [url absoluteString]);
    // Pass on the url to the SDK to parse authorization code from the url.
    //    BOOL isValidRedirectLogInURL = [AIMobileLib handleOpenURL:url sourceApplication:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
    
    //    if(!isValidRedirectLogInURL) {
    //        return NO;
    //    }
    
    
    // App may also want to handle url
    return YES;
}

/*- (NSData *)httpBodyForParamsDictionary:(NSDictionary *)paramDictionary
 {
 NSMutableArray *parameterArray = [NSMutableArray array];
 
 [paramDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
 NSString *param = [NSString stringWithFormat:@"%@=%@", key, [self percentEscapeString:obj]];
 [parameterArray addObject:param];
 }];
 
 NSString *string = [parameterArray componentsJoinedByString:@"&"];
 
 return [string dataUsingEncoding:NSUTF8StringEncoding];
 }*/

/*- (NSString *)percentEscapeString:(NSString *)string
 {
 NSString *result = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
 (CFStringRef)string,
 (CFStringRef)@" ",
 (CFStringRef)@":/?@!$&'()*+,;=",
 kCFStringEncodingUTF8));
 return [result stringByReplacingOccurrencesOfString:@" " withString:@"+"];
 }*/


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    NSLog(@"handleOpenURL %@ || %@",[url absoluteString], [url fragment]);
    
    //    BOOL isValidRedirectLogInURL = [AIMobileLib handleOpenURL:url sourceApplication:[[NSBundle mainBundle] bundleIdentifier]];
    
    //    if(isValidRedirectLogInURL)
    //        NSLog(@"true");
    //    else {
    //        NSLog(@"false");
    //        return NO;
    //    }
    
    /*
     NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
     for (NSString *param in [[url absoluteString] componentsSeparatedByString:@"&"]) {
     NSArray *elts = [param componentsSeparatedByString:@"="];
     if([elts count] < 2) continue;
     [params setObject:[elts lastObject] forKey:[elts firstObject]];
     }
     
     NSString * code = [params objectForKey:@"code"];
     NSLog(@"Code in app delegate: %@", code);
     
     NSString * redirect_uri = @"https://128.157.15.244:8883/authresponse/";
     
     NSMutableURLRequest *postReq = [NSMutableURLRequest requestWithURL:[[NSURL alloc] initWithString: @"https://api.amazon.com/auth/o2/token/" ]];
     [postReq setHTTPMethod:@"POST"];
     [postReq setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
     
     NSDictionary* bodyParams = [NSDictionary dictionaryWithObjectsAndKeys:
     @"grant_type", @"authorization_code",
     @"code", code,
     @"client_id", @"amzn1.application-oa2-client.ccde0cdc13f54c5488a444679a472959",
     @"client_secret", @"f002f7611624bfc3b42c336056c39cfbba9185e1af54d5a82aff964dc913fdf0",
     @"redirect_uri", redirect_uri,/\*
     @"code_verifier", @"fortyfour_fortyfour_fortyfour_fortyfour_four", nil];
     
     //                                  [postReq setHTTPBody: [NSKeyedArchiver archivedDataWithRootObject:bodyParams] ];
     [postReq setHTTPBody:[self httpBodyForParamsDictionary:bodyParams]];
     
     NSOperationQueue *queue = [[NSOperationQueue alloc] init];
     
     [NSURLConnection sendAsynchronousRequest:postReq queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
     NSLog(@"Response URL: %@", [response URL]);
     NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
     NSLog(@"Response body: %@", responseBody);
     NSLog(@"Error: %ld", (long)[error code]);
     
     if([[[response URL] absoluteString] isEqualToString:[[[DREchoHandler alloc] init] AVS_TOKEN_RESPONSE_URL] ]) {
     NSLog(@"Got final auth token: %@", [data base64EncodedStringWithOptions:0]);
     }
     [[HTTPServer sharedHTTPServer] start];
     
     //                                       [[UIApplication sharedApplication] openURL:[response URL]];
     //                                       [[[UIApplication sharedApplication] delegate] application:[UIApplication sharedApplication] handleOpenURL:[response URL]];
     }];*/
    
    
    // App may also want to handle url
    return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    //    NSLog(@"stopping");
    //    [[HTTPServer sharedHTTPServer] stop];
}

- (DRViewController *) viewController {
    return viewController;
}

- (SecKeyRef)getPublicKeyRef {
    
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"5705b3b89f" ofType:@"der"];
    NSData *certData = [NSData dataWithContentsOfFile:resourcePath];
    SecCertificateRef cert = SecCertificateCreateWithData(NULL, (CFDataRef)certData);
    SecKeyRef key = NULL;
    SecTrustRef trust = NULL;
    SecPolicyRef policy = NULL;
    
    if (cert != NULL) {
        policy = SecPolicyCreateBasicX509();
        if (policy) {
            if (SecTrustCreateWithCertificates((CFTypeRef)cert, policy, &trust) == noErr) {
                SecTrustResultType result;
                OSStatus res = SecTrustEvaluate(trust, &result);
                
                //Check the result of the trust evaluation rather than the result of the API invocation.
                if (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified) {
                    key = SecTrustCopyPublicKey(trust);
                }
            }
        }
    }
    if (policy) CFRelease(policy);
    if (trust) CFRelease(trust);
    if (cert) CFRelease(cert);
    return key;
}

SecKeyRef getPrivateKeyRef() {
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"5705b3b89f" ofType:@"p12"];
    NSData *p12Data = [NSData dataWithContentsOfFile:resourcePath];
    
    NSMutableDictionary * options = [[NSMutableDictionary alloc] init];
    
    SecKeyRef privateKeyRef = NULL;
    
    //change to the actual password you used here
    [options setObject:@"flymetothemoon" forKey:(id)kSecImportExportPassphrase];
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    
    OSStatus securityError = SecPKCS12Import((CFDataRef) p12Data,
                                             (CFDictionaryRef)options, &items);
    
    if (securityError == noErr && CFArrayGetCount(items) > 0) {
        CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
        SecIdentityRef identityApp =
        (SecIdentityRef)CFDictionaryGetValue(identityDict,
                                             kSecImportItemIdentity);
        
        securityError = SecIdentityCopyPrivateKey(identityApp, &privateKeyRef);
        if (securityError != noErr) {
            privateKeyRef = NULL;
        }
    }
    //    [options release];
    CFRelease(items);
    return privateKeyRef;
}

SecKeyRef getPrivateKeywithRawKey(NSData *pfxkeydata)
{
    NSMutableDictionary * options = [[NSMutableDictionary alloc] init];
    
    // Set the public key query dictionary
    //change to your .pfx  password here
    [options setObject:@"flymetothemoon" forKey:(id)kSecImportExportPassphrase];
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    
    OSStatus securityError = SecPKCS12Import((CFDataRef) pfxkeydata,
                                             (CFDictionaryRef)options, &items);
    
    CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
    SecIdentityRef identityApp =
    (SecIdentityRef)CFDictionaryGetValue(identityDict,
                                         kSecImportItemIdentity);
    //NSLog(@"%@", securityError);
    
    assert(securityError == noErr);
    SecKeyRef privateKeyRef;
    SecIdentityCopyPrivateKey(identityApp, &privateKeyRef);
    
    return privateKeyRef;
    
}

- (OSStatus)extractIdentity:(CFDataRef)inP12Data :(SecIdentityRef*)identity {
    OSStatus securityError = errSecSuccess;
    
    CFStringRef password = CFSTR("flymetothemoon");
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };
    
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import(inP12Data, options, &items);
    
    if (securityError == 0) {
        CFDictionaryRef ident = CFArrayGetValueAtIndex(items,0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue(ident, kSecImportItemIdentity);
        *identity = (SecIdentityRef)tempIdentity;
    }
    
    if (options) {
        CFRelease(options);
    }
    
    return securityError;
}

- (CFDataRef) persistentRefForIdentity: (SecIdentityRef) identity {
    OSStatus status = errSecSuccess;
    
    CFTypeRef  persistent_ref = NULL;
    const void *keys[] =   { kSecReturnPersistentRef, kSecValueRef };
    const void *values[] = { kCFBooleanTrue,          identity };
    CFDictionaryRef dict = CFDictionaryCreate(NULL, keys, values,
                                              2, NULL, NULL);
    status = SecItemAdd(dict, &persistent_ref);
    
    if(status)
        NSLog(@"identity add status: %d", (int)status);
    
    if (dict)
        CFRelease(dict);
    
    return (CFDataRef)persistent_ref;
}

@end
