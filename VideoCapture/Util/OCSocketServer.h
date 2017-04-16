//
//  OCSocketServer.h
//  iOSServerTest
//
//  Created by 孙军 on 2017/4/14.
//  Copyright © 2017年 sunjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@class MXCaptureVideoViewController;

@interface OCSocketServer : NSObject <GCDAsyncSocketDelegate>

@property (retain,nonatomic) GCDAsyncSocket *socket;
@property (strong,nonatomic) NSMutableArray *clientSocket;
@property (retain,nonatomic) dispatch_queue_t golbalQueue;
@property (retain,atomic) MXCaptureVideoViewController *controller;

-(void)startServerWithController:(MXCaptureVideoViewController *)controller;

@end
