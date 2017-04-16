//
//  OCSocketClient.h
//  VideoCapture
//
//  Created by 孙军 on 2017/4/14.
//  Copyright © 2017年 dong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@class MXCaptureVideoViewController;

@interface OCSocketClient : NSObject <GCDAsyncSocketDelegate>

@property (retain, nonatomic) GCDAsyncSocket *socket;
@property (retain, atomic) MXCaptureVideoViewController *controller;

- (void)connect2Server:(NSString *)host port:(int)port withController:(MXCaptureVideoViewController *)controller;
- (void)sendCmd:(NSString *)cmdString;

@end
