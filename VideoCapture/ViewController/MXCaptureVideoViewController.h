//
//  MXCaptureVideoViewController.h
//  VideoCapture
//
//  Created by michaelxing on 2017/3/5.
//  Copyright © 2017年 dong. All rights reserved.
//

#import <UIKit/UIKit.h>

enum CMDTag {
    START_RECORDING = 0,
    NEXT,
    PREVIOUS,
    STOP,
    SEND_VIDEO_CLIP,
    SEND_PREVIEW_PICTURE,
    EXPORT_VIDEO
};

@interface MXCaptureVideoViewController : UIViewController

@property (atomic) BOOL isControlPeer;

//START_RECORDING
- (void)playAudio;

//NEXT
- (IBAction)nextLoop:(id)sender;

//PREVIOUS
- (IBAction)forwardLoop:(id)sender;

//STOP
- (void)stopRecordVideo:(BOOL)save;

//SEND_VIDEO_CLIP

//SEND_PREVIEW_PICTURE

//EXPORT_VIDEO
- (IBAction)outputVideo:(id)sender;
@end
