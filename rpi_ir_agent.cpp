/**
 * @file rpi_ir_agent.cpp
 * @author arachnothrone
 * @brief 
 * @version 2.1
 * @date 2022-01-16
 * 
 * @copyright Copyright (c) 2022
 * 
 */

#include <iostream>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include "rpi_ir_agent.h"

using namespace std;


class Denon {
public:
private:
    MEM_STATE_T _state;
};

class IRServer {
public:
    IRServer() {
        ;
    }
    bool ReceiveMessage();
    bool SendMessage();
    bool SendIrCommand();
private:
    RX_MSG_T _rxMessage;
    TX_MSG_T _txMessage;
    char rawMessage[RX_BUFFER_SIZE];
};

class SocketConnection {
public:
    SocketConnection() {
        ;
    }
    void Bind();
    void Recv();
    void Send();
private:
    int _sockfd;
    struct sockaddr_in _serverAddr;
    struct sockaddr_in _clientAddr;
};

int main() {
    return 0;
}