//
//  OCSocketServer.m
//  iOSServerTest
//
//  Created by 孙军 on 2017/4/14.
//  Copyright © 2017年 sunjun. All rights reserved.
//

#import "OCSocketServer.h"
#import "MXCaptureVideoViewController.h"

@implementation OCSocketServer

-(void)startServerWithController:(MXCaptureVideoViewController *)controller {
    
    _controller = controller;
    _clientSocket = [NSMutableArray array];
    //创建全局queue
    _golbalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //创建服务端的socket，注意这里的是初始化的同时已经指定了delegate
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_golbalQueue];
    
    //打开监听端口
    NSError *err;
    [_socket acceptOnPort:12345 error:&err];
    if (!err) {
        NSLog(@"服务开启成功");
    }else{
        NSLog(@"服务开启失败");
    }
}

#pragma mark 有客户端建立连接的时候调用
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    //sock为服务端的socket，服务端的socket只负责客户端的连接，不负责数据的读取。   newSocket为客户端的socket
    NSLog(@"服务端的socket %p 客户端的socket %p",sock,newSocket);
    //保存客户端的socket，如果不保存，服务器会自动断开与客户端的连接（客户端那边会报断开连接的log）
    NSLog(@"%s",__func__);
    [self.clientSocket addObject:newSocket];
    
    //有人建立连接说明是被控制端
    //进入被控制模式
    _controller.isControlPeer = NO;
    
    //newSocket为客户端的Socket。这里读取数据
    [newSocket readDataWithTimeout:-1 tag:100];
}

#pragma mark 服务器写数据给客户端
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"%s",__func__);
    [sock readDataWithTimeout:-1 tag:100];
}

#pragma mark 接收客户端传递过来的数据
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //sock为客户端的socket
    NSLog(@"客户端的socket %p",sock);
    //接收到数据
    NSString *receiverStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"length:%ld",receiverStr.length);
    
    switch ([receiverStr intValue]) {
            
        case START_RECORDING:
            NSLog(@"START_RECORDING receive\n");
            [_controller playAudio];
            break;
            
        case NEXT:
            NSLog(@"NEXT receive\n");
            [_controller nextLoop:nil];
            break;
            
        case PREVIOUS:
            NSLog(@"PREVIOUS receive\n");
            [_controller forwardLoop:nil];
            break;
            
        case STOP:
            NSLog(@"STOP receive\n");
            [_controller stopRecordVideo:YES];
            break;
            
        case SEND_VIDEO_CLIP:
            break;
            
        case SEND_PREVIEW_PICTURE:
            break;
            
        default:
            break;
    }
   /*
    //登录指令
    if([receiverStr hasPrefix:@"iam:"]){
        // 获取用户名
        NSString *user = [receiverStr componentsSeparatedByString:@":"][1];
        // 响应给客户端的数据
        NSString *respStr = [user stringByAppendingString:@"has joined"];
        [sock writeData:[respStr dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    }
    //聊天指令
    if ([receiverStr hasPrefix:@"msg:"]) {
        //截取聊天消息
        NSString *msg = [receiverStr componentsSeparatedByString:@":"][1];
        [sock writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    }
    //quit指令
    if ([receiverStr isEqualToString:@"quit"]) {
        //断开连接
        [sock disconnect];
        //移除socket
        [self.clientSocket removeObject:sock];
    }
    */
    NSLog(@"%s",__func__);
    GCDAsyncSocket *socket = (GCDAsyncSocket *)[self.clientSocket objectAtIndex:0];
    [socket readDataWithTimeout:-1 tag:100];
}

@end
