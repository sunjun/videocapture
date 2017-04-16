//
//  OCSocketClient.m
//  VideoCapture
//
//  Created by 孙军 on 2017/4/14.
//  Copyright © 2017年 dong. All rights reserved.
//

#import "OCSocketClient.h"
#import "MXCaptureVideoViewController.h"

@implementation OCSocketClient

- (void) connect2Server:(NSString *)host port:(int)port withController:(MXCaptureVideoViewController *)controller {
    _controller = controller;
    //初始化socket，这里有两种方式。分别为是主/子线程中运行socket。根据项目不同而定
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];//这种是在主线程中运行
    //_socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)]; 这种是在子线程中运行
    
    //开始连接
    NSError *error = nil;
    [_socket connectToHost:host onPort:port error:&error];
    if(error) {
        NSLog(@"error:%@", error);
    }
    
    //进行了连接操作说明是控制端进入控制模式
    controller.isControlPeer = YES;
}

-(void)sendCmd:(NSString *)cmdString {
    NSData *cmdData = [cmdString dataUsingEncoding: NSUTF8StringEncoding];
    //发送登录指令。-1表示不超时。tag200表示这个指令的标识，很大用处
    [_socket writeData:cmdData withTimeout:-1 tag:cmdString.intValue];
}

#pragma mark -socket的代理

#pragma mark 连接成功

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    //连接成功
    NSLog(@"%s",__func__);
//    [self sendCmd];
}

#pragma mark 断开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    if (err) {
        NSLog(@"连接失败");
    }else{
        NSLog(@"正常断开");
    }
}

#pragma mark 数据发送成功
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"%s",__func__);
    //发送完数据手动读取
    [sock readDataWithTimeout:-1 tag:tag];
}

#pragma mark 读取数据
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //代理是在主/子线程调用
    NSLog(@"%@",[NSThread currentThread]);
    NSString *receiverStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (tag == 200) {
        //登录指令
    }else if(tag == 201){
        //聊天数据
    }
    NSLog(@"%s %@",__func__,receiverStr);
}

@end
