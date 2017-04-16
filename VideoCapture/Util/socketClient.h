//
//  socketClient.h
//  VideoCapture
//
//  Created by 孙军 on 2017/3/30.
//  Copyright © 2017年 dong. All rights reserved.
//

#ifndef socketClient_h
#define socketClient_h

#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>
#include <arpa/inet.h>
#include <errno.h>
#include <unistd.h> // for close

struct socketClient {
    int sockfd;
    struct sockaddr_in    servaddr;
    
};

struct socketClient sClinet;

int createTCPClient(const char *ip, int port);
#endif /* socketClient_h */
