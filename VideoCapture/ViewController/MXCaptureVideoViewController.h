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
    SEND_PREVIEW_PICTURE
};

@interface MXCaptureVideoViewController : UIViewController

@property (atomic) BOOL isControlPeer;
- (IBAction)nextLoop:(id)sender;

@end
