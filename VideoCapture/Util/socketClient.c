//
//  socketClient.c
//  VideoCapture
//
//  Created by 孙军 on 2017/3/30.
//  Copyright © 2017年 dong. All rights reserved.
//

#include "socketClient.h"

int createTCPClient(const char *ip, int port)
{
    
    if ((sClinet.sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        printf("create socket error: %s(errno: %d)\n", strerror(errno), errno);
        return -1;
    }
    
    memset(&sClinet.servaddr, 0, sizeof(sClinet.servaddr));
    sClinet.servaddr.sin_family = AF_INET;
    sClinet.servaddr.sin_port = htons(port);
    if (inet_pton(AF_INET, ip, &sClinet.servaddr.sin_addr) <= 0) {
        printf("inet_pton error");
    }
    
    if (connect(sClinet.sockfd, (struct sockaddr*)&sClinet.servaddr, sizeof(sClinet.servaddr)) < 0) {
        printf("connect error: %s(errno: %d)\n", strerror(errno),errno);
    }
    
    //close(sockfd);
    return 0;
}

void sendCmd(char *cmd)
{
    printf("send msg to server: \n");
    if (send(sClinet.sockfd, cmd, strlen(cmd), 0) < 0) {
        printf("send msg error: %s(errno: %d)\n", strerror(errno), errno);
    }
}

void recvCmd(char *cmd)
{
    printf("recv msg from server: \n");
    if (recv(sClinet.sockfd, cmd, 1024, 0) < 0) {
        printf("send msg error: %s(errno: %d)\n", strerror(errno), errno);
    }
}

void closeSocket()
{
    close(sClinet.sockfd);
}

