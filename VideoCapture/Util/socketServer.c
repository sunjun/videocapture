//
//  socketServer.c
//  VideoCapture
//
//  Created by 孙军 on 2017/3/30.
//  Copyright © 2017年 dong. All rights reserved.
//

#include "socketServer.h"

int createTCPServer()
{
    int    connfd;
    char    buff[4096];
    int     n;
    
    if ((sServer.listenfd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        printf("create socket error: %s(errno: %d)\n", strerror(errno), errno);
    }
    
    memset(&sServer.servaddr, 0, sizeof(sServer.servaddr));
    sServer.servaddr.sin_family = AF_INET;
    sServer.servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    sServer.servaddr.sin_port = htons(6666);
    
    if (bind(sServer.listenfd, (struct sockaddr*)&sServer.servaddr, sizeof(sServer.servaddr)) == -1) {
        printf("bind socket error: %s(errno: %d)\n", strerror(errno), errno);
    }
    
    if (listen(sServer.listenfd, 10) == -1) {
        printf("listen socket error: %s(errno: %d)\n", strerror(errno), errno);
    }
    
    printf("======waiting for client's request======\n");
    
    while (1) {
        if ((sServer.connfd = accept(sServer.listenfd, (struct sockaddr*)NULL, NULL)) == -1) {
            printf("accept socket error: %s(errno: %d)", strerror(errno), errno);
            continue;
        }
        n = recv(sServer.connfd, buff, 4096, 0);
        buff[n] = '\0';
        printf("recv msg from client: %s\n", buff);
    }
    
    return 0;
}
