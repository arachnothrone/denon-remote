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


Denon::Denon() {
    _volume = -40;
    _stereoMode = STANDARD;
    _power = OFF;
    _mute = OFF;
    _dimmer = LEVEL0;
    _input = INPUTMODE;
};

void Denon::UpdateDimmer() {
    if (_dimmer < LEVEL3) {
        _dimmer = (STATE_DIM)((int)_dimmer + 1);
    } else {
        _dimmer = LEVEL0;
    }
}

void Denon::VolumeChangeDb(int dbDelta) {
    _volume += dbDelta;
    if (_volume > VOL_MAX_LIMIT || _volume < VOL_MIN_LIMIT) {
        throw invalid_argument(
            "Trying to set the volume outside limits: (" + 
            to_string(_volume) + " dB. Limits: " + 
            to_string(VOL_MIN_LIMIT) + ", " + 
            to_string(VOL_MAX_LIMIT) + ")"
        );
    }
}

void Denon::SetPower(STATE_BINARY pwr) {
    _power = pwr;
}

void Denon::UpdateMute(void) {
    if (_mute == OFF) {
        _mute = ON;
    } else {
        _mute = OFF;
    }
}

void Denon::SetStereoMode(STATE_MODE mode) {
    _stereoMode = mode;
}

void Denon::SetInput(STATE_INPUT input) {
    _input = input;
}

void Denon::PrintState() {
    cout << 
        "Current state: volume=" << _volume << 
        ", stereoMode=" << _stereoMode << 
        ", power=" << _power <<
        ", mute=" << _mute <<
        ", dimmer=" << _dimmer <<
        ", input=" << _input <<
        endl;
}

string Denon::SerializeDenonState() {
    return string("" + 
        to_string(_power) + "," +
        to_string(_volume) + "," +
        to_string(_mute) + "," + 
        to_string(_stereoMode) + "," + 
        to_string(_input) + "," + 
        to_string(_dimmer)
    );
}

int Denon::GetVolume() {
    return _volume;
}

void Denon::SetVolume(int vol) {
    _volume = vol;
}

SocketConnection::SocketConnection(const int rxport) {
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

int SocketConnection::Bind() {
    int result = ::bind(
        _sockfd, 
        (const struct sockaddr *)&_serverAddr, 
        sizeof(_serverAddr)
    ); // <--- err, close sock
    
    return result;
}

string SocketConnection::Recv() {
    unsigned int len, n;
    string result;
    len = sizeof(_clientAddr);

    n = recvfrom(
        _sockfd, 
        (char *)_buffer, 
        RX_BUFFER_SIZE,
        MSG_WAITALL, 
        (struct sockaddr *) &_clientAddr, 
        &len
    );

    if (n >= RX_BUFFER_SIZE) n = RX_BUFFER_SIZE - 1; // <--- err if <0, close sock
    _buffer[n] = '\0';

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
        ntohs(_clientAddr.sin_port)
    );

    // struct timespec ts = {.tv_sec = 1, .tv_nsec = 80e6};  
    // nanosleep(&ts, NULL);

    result = _buffer;
    return result;
}

void SocketConnection::Send(const string msgString, const int msgStrSize) {
    char time_stmp[] = "0000-00-00 00:00:00";
    getTimeStamp(time_stmp, sizeof(time_stmp));

    sendto(
        _sockfd, 
        &msgString[0], 
        msgStrSize, 
        /*MSG_CONFIRM*/SOCK_SND_FLAG, 
        (const struct sockaddr *) &_clientAddr, 
        sizeof(_clientAddr)
    ); // <-- err, close sock
    
    printf("%s Response sent: %s [%s:%0d]\n", 
        time_stmp, 
        msgString.c_str(),
        inet_ntop(AF_INET, &_clientAddr.sin_addr.s_addr, _clientAddrString, sizeof(_clientAddrString)), 
        ntohs(_clientAddr.sin_port)
    );
}

IRServer::IRServer(const int rxport, Denon& dstate): SocketConnection(rxport), _denonState(dstate) {};

void IRServer::Deserialize(const string& msg) {
    std::string::size_type sz;
    _rxMessage.msgPrefix = msg.substr(RXMSGPREF, RXMSGPREFSZ);
    _rxMessage.cmdCode = stoi(msg.substr(RXMSGCMDCODE, RXMSGCMDCODESZ));
    _rxMessage.cmdDescription = msg.substr(RXMSGCMDDESCR, RXMSGCMDDESCRSZ);
    if (_rxMessage.cmdCode >= CMD_INCREASEVOL && _rxMessage.cmdCode <= CMD_DECREASEVOL) {
        _rxMessage.cmdParamValue = stoi(msg.substr(RXMSGCMDPARVAL, RXMSGCMDPARVALSZ));
    }
}

void IRServer::Serialize() {}

bool IRServer::ReceiveMessage() {
    Deserialize(Recv());
    SendIrCommand(_rxMessage.cmdCode);
    
    return true;
}

bool IRServer::SendMessage() {
    const string replyStr = _denonState.SerializeDenonState();
    Send(replyStr, replyStr.size());
    
    return true;
}

int IRServer::GetCmdCode() {
    return _rxMessage.cmdCode;
}

void IRServer::SetVolumeTo(int value) {
    int i, deltaVol;
    //char command[50];
    //struct timespec ts = {.tv_sec = 0, .tv_nsec = 80e6};         // 80 ms (was 120 ms = 12e7) delay
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 80e6;
    string command;

    if (_denonState.GetVolume() > value) {
        command = "irsend SEND_ONCE Denon_RC-978 KEY_VOLUMEDOWN";
    } else {
        command = "irsend SEND_ONCE Denon_RC-978 KEY_VOLUMEUP";
    }

    deltaVol = abs(abs(_denonState.GetVolume()) - abs(value));
    
    nanosleep(&ts, NULL);

    for (i = 0; i < deltaVol; i++) {
        if (_denonState.GetVolume() >= VOL_MAX_LIMIT) {
            //printf("SetVolumeTo: Maximum reached (%d dB)\n", VOL_MAX_LIMIT);
            cout << "SetVolumeTo: Maximum reached (" << VOL_MAX_LIMIT << " dB)" << endl;
            break;
        } else {
            system(command.c_str());
            //printf("Executing: %s (%d)\n", command, strlen(command));
            cout << "Executing: " << command << ", length=" << command.length() << endl;

            // 80 ms pause between two steps
            nanosleep(&ts, NULL);
        }
    }

    // pDenonState->volume = value;
    // printf("SetVolumeTo: set to %d\n", pDenonState->volume);
    _denonState.VolumeChangeDb(value - _denonState.GetVolume());
    cout << "SetVolumeTo: set to " << _denonState.GetVolume() << endl;
}

void IRServer::SetMinimumVolume(double timeIntervalSec) {
    //struct timespec ts = {.tv_sec = 7, .tv_nsec = 5e8};         // for 4.5 sec delay
    struct timespec ts; // = {.tv_sec = (int) timeIntervalSec, .tv_nsec = (timeIntervalSec - ((int) timeIntervalSec)) * 1e9};
    ts.tv_sec = (int) timeIntervalSec;
    ts.tv_nsec = (timeIntervalSec - ((int) timeIntervalSec)) * 1e9;
    system("irsend SEND_START Denon_RC-978 KEY_VOLUMEDOWN");
    nanosleep(&ts, NULL);
    system("irsend SEND_STOP Denon_RC-978 KEY_VOLUMEDOWN");
    ts.tv_sec = 0;
    ts.tv_nsec = 5e8;
    nanosleep(&ts, NULL);
    system("irsend SEND_ONCE Denon_RC-978 KEY_VOLUMEUP");
    _denonState.SetVolume(-70);
}

bool IRServer::SendIrCommand(int commandCode) {
    bool result = true;
    string command;

    switch (commandCode) {
        case CMD_GETSTATE:
            _denonState.PrintState();
            break;
        case CMD_DIMMER ... CMD_INPUT_EXTIN:
            // Execute LIRC IR command
            // system("irsend SEND_ONCE Denon_RC-978 DIMMER");
            command = "irsend SEND_ONCE Denon_RC-978 " + _AVRCMDMAP.at(commandCode).first;
            system(command.c_str());
            // cout << command << endl;
            // cout << 
            //     "irsend SEND_ONCE Denon_RC-978 " << 
            //     _AVRCMDMAP.at(commandCode).first << endl;
            // Call corresponding function, pass it the state pointer
            _AVRCMDMAP.at(commandCode).second(_denonState);
            break;
        case CMD_INCREASEVOL:
            SetVolumeTo(_denonState.GetVolume() + _rxMessage.cmdParamValue);
            break;
        case CMD_DECREASEVOL:
            SetVolumeTo(_denonState.GetVolume() - _rxMessage.cmdParamValue);
            break;
        
        default:
            /* Unknown command */
            break;
    }

    return result;
};

/**
 * @brief Get the Time Stamp
 * 
 * @param pTimeStamp 
 * @param buffSize 
 */
void getTimeStamp(char* pTimeStamp, int buffSize) {
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
            tm->tm_sec
        );
    }
}

int main() {
    Denon Denon;
    IRServer Server(RX_PORT, Denon);

    bool shutDownServer = false;
    while (!shutDownServer) {
        Server.ReceiveMessage();
        Server.SendMessage();
        if (Server.GetCmdCode() == 17) {
            shutDownServer = true;
        }
    }
    return 0;
}


void FuncDimmer(Denon& dState) {
    dState.UpdateDimmer();
}

void FuncVolumeUp(Denon& dState) {
    dState.VolumeChangeDb(+1);
}

void FuncVolumeDown(Denon& dState) {
    dState.VolumeChangeDb(-1);
}

void FuncPowerOn(Denon& dState) {
    dState.SetPower(ON);
}

void FuncPowerOff(Denon& dState) {
    dState.SetPower(OFF);
}

void FuncMuting(Denon& dState) {
    dState.UpdateMute();
}

void FuncSoundModeStereo5ch7ch(Denon& dState) {
    dState.SetStereoMode(CH5CH7);
}

void FuncSoundModeDspSimulation(Denon& dState) {
    dState.SetStereoMode(DSPSIM);
}

void FuncSoundModeStandard(Denon& dState) {
    dState.SetStereoMode(STANDARD);
}

void FuncSoundModeCinema(Denon& dState) {
    dState.SetStereoMode(CINEMA);
}

void FuncSoundModeMusic(Denon& dState) {
    dState.SetStereoMode(MUSIC);
}

void FuncSoundModeDirect(Denon& dState) {
    dState.SetStereoMode(DIRECT);
}
void FuncSoundModeStereo(Denon& dState) {
    dState.SetStereoMode(STEREO);
}

void FuncSoundModeVirtSurround(Denon& dState) {
    dState.SetStereoMode(VIRTSURRND);
}

void FuncInputMode(Denon& dState) {
    dState.SetInput(INPUTMODE);
}

void FuncInputAnalog(Denon& dState) {
    dState.SetInput(INPUTANALOG);
}

void FuncInputExtIn(Denon& dState) {
    dState.SetInput(INPUTEXTIN);
}
