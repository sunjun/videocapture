//
//  socketServer.h
//  VideoCapture
//
//  Created by 孙军 on 2017/3/30.
//  Copyright © 2017年 dong. All rights reserved.
//

#ifndef socketServer_h
#define socketServer_h

#include <stdio.h>
#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>
#include <arpa/inet.h>
#include <errno.h>
#include <unistd.h> // for close

struct socketServer {
    int sockfd;
    int listenfd;
    int connfd;
    struct sockaddr_in servaddr;
};

struct socketServer sServer;
int createTCPServer();
#endif /* socketServer_h */
