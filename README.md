

Basic Control SDK iOS
=====================

This SDK provides access to basic driving controls from a custom iOS application.

1. Copy the DoubleControlSDK.framework into your app's folder
2. Add DoubleControlSDK.framework to your app
3. Add the ExternalAccessory.framework to your app
4. Add an entry in Info.plist for "Supported external accessory protocols" > Item 0 = com.doublerobotics.pancho
5. #import &lt;DoubleControlSDK/DoubleControlSDK.h&gt;
6. Add &lt;DRDoubleDelegate&gt;
7. [DRDouble sharedDouble].delegate = self;

DRDouble
========
```
@property (nonatomic, assign) id <DRDoubleDelegate> delegate;
@property (nonatomic, readonly) float poleHeightPercent;
@property (nonatomic, readonly) int kickstandState;
@property (nonatomic, readonly) float batteryPercent;
@property (nonatomic, readonly) BOOL batteryIsFullyCharged;
@property (nonatomic, readonly) NSString *firmwareVersion;
@property (nonatomic, readonly) float leftEncoderDeltaInches;
@property (nonatomic, readonly) float rightEncoderDeltaInches;
@property (nonatomic, readonly) NSString *serial;

- (void)drive:(DRDriveDirection)forwardBack turn:(float)leftRight; // leftRight is -1.0 to 1.0
- (void)variableDrive:(float)forwardBack turn:(float)leftRight; // drive is -1.0 to 1.0, leftRight is -1.0 to 1.0 (0.0 is stop on both)
- (void)turnByDegrees:(float)theDegrees;
- (void)poleUp;
- (void)poleDown;
- (void)poleStop;
- (void)deployKickstands;
- (void)retractKickstands;
- (void)startTravelData;
- (void)stopTravelData;
```

DRDoubleDelegate
================
```
- (void)doubleDidConnect:(DRDouble *)theDouble;
- (void)doubleDidDisconnect:(DRDouble *)theDouble;
- (void)doubleStatusDidUpdate:(DRDouble *)theDouble;
- (void)doubleDriveShouldUpdate:(DRDouble *)theDouble;
- (void)doubleTravelDataDidUpdate:(DRDouble *)theDouble;
```
