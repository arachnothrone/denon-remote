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
#include <time.h>
#include <cstring>
#include "rpi_ir_agent.h"

using namespace std;


class Denon {
public:
    Denon() {
        _state.volume = -40;
        _state.stereoMode = STANDARD;
        _state.power = OFF;
        _state.mute = OFF;
        _state.dimmer = LEVEL0;
        _state.input = INPUTMODE;
    };
private:
    MEM_STATE_T _state;
};

class SocketConnection {
public:
    SocketConnection(const int rxport) {
        _rxPort = rxport;
        _sockfd = socket(AF_INET, SOCK_DGRAM, 0); // <---- err
        memset(&_serverAddr, 0, sizeof(_serverAddr));
        memset(&_clientAddr, 0, sizeof(_clientAddr));

        _serverAddr.sin_family = AF_INET; // IP v4
        _serverAddr.sin_addr.s_addr = INADDR_ANY;
        _serverAddr.sin_port = htons(RX_PORT);
        int bindResult = Bind();
        if (bindResult < 0) {
            perror("UDP port binding failed");
            exit(EXIT_FAILURE);
        }
        
    }
    int Bind() {
        int result = ::bind(_sockfd, (const struct sockaddr *)&_serverAddr, sizeof(_serverAddr)); // <--- err, close sock
        return result;
    };
    string Recv() {
        unsigned int len, n;
        string result;
        len = sizeof(_clientAddr);
        n = recvfrom(_sockfd, (char *)_buffer, RX_BUFFER_SIZE, MSG_WAITALL, (struct sockaddr *) &_clientAddr, &len);
        if (n >= RX_BUFFER_SIZE) n = RX_BUFFER_SIZE - 1; // <--- err if <0, close sock
        _buffer[n] = '\0';
        //char clientAddrString[INET_ADDRSTRLEN];
        //char* time_stmp = getTimeStamp();
        char time_stmp[] = "0000-00-00 00:00:00";
        getTimeStamp(time_stmp, sizeof(time_stmp));
        printf("%s Received request: %s [%s:%0d]\n", 
            time_stmp, 
            _buffer, 
            inet_ntop(
                AF_INET, 
                &_clientAddr.sin_addr.s_addr, 
                _clientAddrString, 
                sizeof(_clientAddrString)
            ), 
            ntohs(_clientAddr.sin_port));
        //free(time_stmp);

        // struct timespec ts = {.tv_sec = 1, .tv_nsec = 80e6};  
        // nanosleep(&ts, NULL);

        // Send();
        result = _buffer;
        return result;
    };
    void Send(const string msgString, const int msgStrSize) {
        //char replBuf[] = "...reply...";
        //char* replBuf;
        const string replyString = "0123,,, repl +++_+++";
        //strcpy(char_array, s.c_str());
        //replBuf = &replyString[0];

        char time_stmp[] = "0000-00-00 00:00:00";
        getTimeStamp(time_stmp, sizeof(time_stmp));

        printf("SOCK_SND_FLAG=%0x\n", SOCK_SND_FLAG);
        sendto(_sockfd, &replyString[0], replyString.size(), /*MSG_CONFIRM*/SOCK_SND_FLAG, (const struct sockaddr *) &_clientAddr, sizeof(_clientAddr)); // <-- err, close sock
        //sendto(_sockfd, &msgString[0], msgStrSize, /*MSG_CONFIRM*/SOCK_SND_FLAG, (const struct sockaddr *) &_clientAddr, sizeof(_clientAddr)); // <-- err, close sock
        //sendto(_sockfd, replBuf, strlen(replBuf), /*MSG_CONFIRM*/SOCK_SND_FLAG, (const struct sockaddr *) &_clientAddr, sizeof(_clientAddr));
        printf("%s Response sent: power=%d, vol=%d, mode=%d, input=%d, mute=%d, dimmer=%d [%s:%0d]\n", time_stmp, 
            22, 23, 44, 
            55, 1, 2, 
            inet_ntop(AF_INET, &_clientAddr.sin_addr.s_addr, _clientAddrString, sizeof(_clientAddrString)), 
            ntohs(_clientAddr.sin_port));
    }
private:
    int _rxPort;
    int _sockfd;
    struct sockaddr_in _serverAddr;
    struct sockaddr_in _clientAddr;
    char _buffer[RX_BUFFER_SIZE];
    char _clientAddrString[INET_ADDRSTRLEN];
};

class IRServer : public SocketConnection {
public:
    IRServer(const int rxport, Denon& dstate): SocketConnection(rxport) {};
    void Deserialize(const string& msg) {
        std::string::size_type sz;
        cout << msg << endl;
        cout << msg.substr(RXMSGCMDCODE, RXMSGCMDCODESZ)<< endl;
        _rxMessage.msgPrefix = msg.substr(RXMSGPREF, RXMSGPREFSZ);
        _rxMessage.cmdCode = stoi(msg.substr(RXMSGCMDCODE, RXMSGCMDCODESZ));
        _rxMessage.cmdDescription = msg.substr(RXMSGCMDDESCR, RXMSGCMDDESCRSZ);
        //if (RXMSGCMDCODESZ + RXMSGPREFSZ + )
        string description(""), paramValue("");
        cout << "==> " << msg.substr(RXMSGCMDCODESZ + RXMSGPREFSZ) << endl;
        for (auto& c : msg.substr(RXMSGCMDCODESZ + RXMSGPREFSZ)) {
            if (isdigit(c)) {
                paramValue.push_back(c);
                cout << "+++++++++++\n";
            } else {
                description.push_back(c);
            }
        }
        cout << "--->" << description << ": " << paramValue << endl;
        //_rxMessage.cmdParamValue = stoi(msg.substr(RXMSGCMDPARVALBGN, RXMSGCMDPARVALEND));
        cout 
            << "Rx prefix:                  " << _rxMessage.msgPrefix << endl
            << "Rx command code:            " << _rxMessage.cmdCode << endl
            << "Rx command description:     " << _rxMessage.cmdDescription << endl
//            << "Rx command parameter value: " << _rxMessage.cmdParamValue
            << endl;
    }
    void Serialize() {}
    bool ReceiveMessage() {
        Deserialize(Recv());
        SendIrCommand(_rxMessage.cmdCode);

        return true;
    }
    bool SendMessage() {
        const string replyStr = "0123,,, repl +++_$$$";
        Send(replyStr, replyStr.size());
        return true;
    };
    int GetCmdCode() {
        return _rxMessage.cmdCode;
    }
    bool SendIrCommand(int commandCode) {
        bool result = true;
        
        return result;
    };
private:
    //SocketConnection _socket;
    RX_MSG_T _rxMessage;
    TX_MSG_T _txMessage;
    char rawMessage[RX_BUFFER_SIZE];
};

/**
 * @brief Get the Time Stamp
 * 
 * @param pTimeStamp 
 * @param buffSize 
 */
void getTimeStamp(char* pTimeStamp, int buffSize)
{
    time_t currentTime;
    struct tm* tm;
    currentTime = time(NULL);
    tm = localtime(&currentTime);
    
    if (buffSize >= TS_BUF_SIZE) { 
        sprintf(pTimeStamp, "%04d-%02d-%02d %02d:%02d:%02d", 
            tm->tm_year + 1900, 
            tm->tm_mon + 1, 
            tm->tm_mday, 
            tm->tm_hour, 
            tm->tm_min, 
            tm->tm_sec);
    }
}

int main() {
    Denon Denon;
    IRServer Server(RX_PORT, Denon);

    bool shutDownServer = false;
    while (!shutDownServer) {
        Server.ReceiveMessage();
        Server.SendMessage();
        if (Server.GetCmdCode() == 40) {
            shutDownServer = true;
        }
    }

    return 0;
}
