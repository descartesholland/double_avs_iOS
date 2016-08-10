
//  DRAudioController.c
//  DoubleBasicHelloWorld
//
//  Created by Descartes Holland on 8/3/16.
//

#include "DRAudioController.h"

#import "DREchoHandler.h"
#import "AVFoundation/AVAudioRecorder.h"

#import "AVFoundation/AVAudioSession.h"



@implementation DRAudioController


- (void) startRecording{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
    // Create a new dated file
    //    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
//    NSString *caldate = @"test";//[now description];
    recorderFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                            [NSString stringWithFormat: @"%@.%@", @"temp", @"wav"]];

    
//    recorderFilePath = [NSString stringWithFormat:@"%@/temp.wav", documentsDirectory];
    //[documentsDirectory stringByAppendingPathComponent:
                        //[[NSString stringWithFormat:@"%@.wav", caldate] retain]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:recorderFilePath isDirectory:false] ) {
        if([fm createFileAtPath:recorderFilePath contents:[[NSData alloc] init] attributes:nil])
            NSLog(@"File Created");
        else
            NSLog(@"File Creation Failed");
    }
    else {
        NSError* y = nil;
        NSLog(@"File exists");
        [fm removeItemAtPath:recorderFilePath error:&y];
        if([fm createFileAtPath:recorderFilePath contents:[[NSData alloc] init] attributes:nil])
            NSLog(@"File Created");
        else
            NSLog(@"File Creation Failed");

    }
    
//    UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithTitle:@"Stop" style:UIBarButtonItemStyleBordered  target:self action:@selector(stopRecording)];
//    self.navigationItem.rightBarButtonItem = stopButton;
//    [stopButton release];
    NSLog(@"startRecording() in DRAudioController with recorderFilePath %@", recorderFilePath);
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err){
        NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }
    [audioSession setActive:YES error:&err];
    err = nil;
    if(err){
        NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }
    
    recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    [recordSetting setValue :[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    
    
    err = nil;
    recorder = [[ AVAudioRecorder alloc] initWithURL:[[NSURL alloc ] initWithString:recorderFilePath] settings:recordSetting error:&err];
    if(!recorder){
        NSLog(@"recorder: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
                                   message: [err localizedDescription]
                                  delegate: nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [alert show];
        [alert release];
        return; 
    }
    
    //prepare to record
    [recorder setDelegate:self];
    [recorder prepareToRecord];
    recorder.meteringEnabled = YES;
    
    BOOL audioHWAvailable = audioSession.inputIsAvailable;
    if (! audioHWAvailable) {
        UIAlertView *cantRecordAlert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
                                   message: @"Audio input hardware not available"
                                  delegate: nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [cantRecordAlert show];
        [cantRecordAlert release];
        return;
    }
    
    // start recording
    [recorder recordForDuration:(NSTimeInterval) 3];
    
}

- (void) stopRecording{
    NSLog(@"stopRecording in DRAudioController with recorderFilePath %@", recorderFilePath);
    
    [recorder stop];
    
    NSURL *url = [NSURL fileURLWithPath: recorderFilePath];
    NSError *err = nil;
    audioData = [NSData dataWithContentsOfFile:[url path] options: 0 error:&err];
    if(!audioData)
        NSLog(@"audio data: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
//        [editedObject setValue:[NSData dataWithContentsOfURL:url] forKey:editedFieldKey];
    
    //[recorder deleteRecording];
    
    NSLog(@"About to generate voice request with audioData lengith %ld", [audioData length]);
    [[DREchoHandler sharedEchoHandler] generateVoiceRequest : audioData];
    
//    [audioData release];
//    NSFileManager *fm = [NSFileManager defaultManager];
    
//    NSError *err = nil;
//    [fm removeItemAtPath:[[NSURL fileURLWithPath: recorderFilePath]  path] error:&err];
//    if(err)
//        NSLog(@"File Manager: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);

    
//        UIBarButtonItem *startButton = [[UIBarButtonItem alloc] initWithTitle:@"Record" style:UIBarButtonItemStyleBordered  target:self action:@selector(startRecording)];
//        self.navigationItem.rightBarButtonItem = startButton;
//        [startButton release];
     
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *) aRecorder successfully:(BOOL)flag {
    
    NSLog (@"audioRecorderDidFinishRecording:successfully:");
    

}

+ (NSData*) audioData {
    return [self audioData];
}

@end