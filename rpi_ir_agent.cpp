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
#include "rpi_ir_agent.h"

using namespace std;


class Denon {
public:
private:
    MEM_STATE_T _state;
};

class IRServer {
public:
    bool ReceiveMessage();
    bool SendMessage();
    bool SendIrCommand();
private:
    RX_MSG_T _rxMessage;
    TX_MSG_T _txMessage;
    char rawMessage[RX_BUFFER_SIZE];
};