//
//  DRAudioController.h
//  DoubleBasicHelloWorld
//
//  Created by Descartes Holland on 8/3/16.
//  Copyright © 2016 Double Robotics, Inc. All rights reserved.
//

#ifndef DRAudioController_h
#define DRAudioController_h

#endif /* DRAudioController_h */

#import "AVFoundation/AVAudioRecorder.h"


@interface DRAudioController : NSObject <AVAudioRecorderDelegate> {
    AVAudioRecorder* recorder;
    NSMutableDictionary* recordSetting;
    
    NSString* recorderFilePath;
    NSData* audioData;
}

//@property (readonly) AudioBuffer audioBuffer;
//@property (readonly) AudioComponentInstance audioUnit;


//-(AudioProcessor*)init;

- (void) startRecording;

- (void) stopRecording;
//-(void)hasError:(int)statusCode:(char*)file:(int)line;
- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *) aRecorder :(BOOL)flag;

+ (NSData*) audioData;

@end