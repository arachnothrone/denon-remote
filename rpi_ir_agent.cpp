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
#include <sys/select.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <time.h>
#include <cstring>
#include <getopt.h>
#include "rpi_ir_agent.h"

#include <unistd.h>     // close socket


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
    
    if ((_volume + dbDelta) > VOL_MAX_LIMIT || (_volume + dbDelta) < VOL_MIN_LIMIT) {
        throw std::invalid_argument(
            "Trying to set the volume outside limits: (" + 
            std::to_string(_volume) + " dB. Limits: " + 
            std::to_string(VOL_MIN_LIMIT) + ", " + 
            std::to_string(VOL_MAX_LIMIT) + ")"
        );
    } else {
        _volume += dbDelta;
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
    std::cout << 
        "Current state: volume=" << _volume << 
        ", stereoMode=" << _stereoMode << 
        ", power=" << _power <<
        ", mute=" << _mute <<
        ", dimmer=" << _dimmer <<
        ", input=" << _input <<
        std::endl;
}

std::string Denon::SerializeDenonState() {
    return std::string("" + 
        std::to_string(_power) + "," +
        std::to_string(_volume) + "," +
        std::to_string(_mute) + "," + 
        std::to_string(_stereoMode) + "," + 
        std::to_string(_input) + "," + 
        std::to_string(_dimmer)
    );
}

int Denon::GetVolume() {
    return _volume;
}

void Denon::SetVolume(int vol) {
    _volume = vol;
}

void Denon::SetAutoPowerOffEnable(STATE_BINARY autoPoff) {
    _autoPwrOffEnable = autoPoff;
}

int Denon::GetPowerState() {
    return _power;
}

int Denon::GetAutoPowerOffEnable() {
    return _autoPwrOffEnable;
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
    int result = bind(
        _sockfd, 
        (const struct sockaddr *)&_serverAddr, 
        sizeof(_serverAddr)
    ); // <--- err, close sock
    
    return result;
}

int SocketConnection::GetSocketFdId() {
    return _sockfd;
}

std::string SocketConnection::Recv() {
    unsigned int len, n;
    std::string result;
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

    result = _buffer;
    return result;
}

void SocketConnection::Send(const std::string msgString, const int msgStrSize) {
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

void IRServer::Deserialize(const std::string& msg) {
    std::string::size_type sz;
    int diffVolSign = 1;
    _rxMessage.msgPrefix = msg.substr(RXMSGPREF, RXMSGPREFSZ);
    _rxMessage.cmdCode = stoi(msg.substr(RXMSGCMDCODE, RXMSGCMDCODESZ));
    _rxMessage.cmdDescription = msg.substr(RXMSGCMDDESCR, RXMSGCMDDESCRSZ); //TODO: remove description
    
    /* Parse Increase/decrease Volume parameter value */
    if (_rxMessage.cmdCode >= CMD_INCREASEVOL && _rxMessage.cmdCode <= CMD_DECREASEVOL) {
        if (_rxMessage.cmdCode == CMD_DECREASEVOL) {diffVolSign = -1;}
        _rxMessage.cmdParamValue = stoi(msg.substr(RXMSGCMDPARVAL, RXMSGCMDPARVALSZ)) * diffVolSign;
    }

    /* Parse Auto Power Off Enable parameter value */
    if (_rxMessage.cmdCode == CMD_AUTOPWROFF) {
        _rxMessage.cmdParamValue = stoi(msg.substr(RXMSGCMDPARAPOFF, RXMSGCMDPARAPOFFSZ));
    }
}

void IRServer::Serialize() {}

bool IRServer::ReceiveMessage() {
    Deserialize(Recv());
    SendIrCommand(_rxMessage.cmdCode);
    
    return true;
}

bool IRServer::SendMessage() {
    const std::string replyStr = _denonState.SerializeDenonState();
    Send(replyStr, replyStr.size());
    
    return true;
}

int IRServer::GetCmdCode() {
    return _rxMessage.cmdCode;
}

void IRServer::SetVolumeTo(int value) {
    int i, deltaVol;      
    struct timespec ts;     // 80 ms (was 120 ms = 12e7) delay
    ts.tv_sec = 0;
    ts.tv_nsec = 80e6;
    std::string command;

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
            std::cout << "SetVolumeTo: Maximum reached (" << VOL_MAX_LIMIT << " dB)" << std::endl;
            break;
        } else {
            system(command.c_str());
            std::cout << "Executing: " << command << ", length=" << command.length() << std::endl;

            // 80 ms pause between two steps
            nanosleep(&ts, NULL);
        }
    }

    _denonState.VolumeChangeDb(value - _denonState.GetVolume());
    std::cout << "SetVolumeTo: set to " << _denonState.GetVolume() << std::endl;
}

void IRServer::SetMinimumVolume(double timeIntervalSec) {
    struct timespec ts;
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
    std::string command;

    switch (commandCode) {
        case CMD_GETSTATE:
            _denonState.PrintState();
            break;
        case CMD_DIMMER ... CMD_INPUT_EXTIN:
            // Execute LIRC IR command
            command = "irsend SEND_ONCE Denon_RC-978 " + _AVRCMDMAP.at(commandCode).first;
            system(command.c_str());

            // Call corresponding function, pass it the state pointer
            _AVRCMDMAP.at(commandCode).second(_denonState);
            break;
        case CMD_INCREASEVOL ... CMD_DECREASEVOL:
            SetVolumeTo(_denonState.GetVolume() + _rxMessage.cmdParamValue);
            break;
        case CMD_AUTOPWROFF:
            _denonState.SetAutoPowerOffEnable((STATE_BINARY)_rxMessage.cmdParamValue);
            break;
        case CMD_CALIBRATE_VOL:
            SetMinimumVolume(3.75);     // 3.75 sec - time interval of sending continuous volume down command:
                                        // ~ 75 ms / 1 dB, lower bound = -70 dB => from -20 to -70 (50 dB): 3750 ms
            SetVolumeTo(-40);           // set calibrated level to -40 dB, from -70 it takes ~9 sec
                                        // Calibration cycle takes ~13 sec
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

int main(int argc, char* argv[]) {
    bool shutDownServer = false;
    int num_ready_fds = 0;
    time_t currentTime;
    struct tm* tm;
    struct tm tm_off;       // Automatic switch off time
    int cli_options;

    while ((cli_options = getopt(argc, argv, "h:m:s:")) != -1) {
        switch (cli_options)
        {
        case 'h':
            tm_off.tm_hour = atoi(optarg);
            break;
        case 'm':
            tm_off.tm_min = atoi(optarg);
            break;
        case 's':
            tm_off.tm_sec = atoi(optarg);
            break;
        
        default:
            std::cout << "To start with automatic switch-off use: " << argv[0] << " [-h hour -m min -s sec]" << std::endl;
            std::cout << "Not using automatic switch off" << std::endl;
            tm_off.tm_hour = 0;
            tm_off.tm_min = 0;
            tm_off.tm_sec = 0;
            break;
        }
    }

    std::cout << "Automatic Power Off at: " 
                << tm_off.tm_hour << ":" 
                << tm_off.tm_min << ":" 
                << tm_off.tm_sec << std::endl; 

    Denon Denon;
    IRServer Server(RX_PORT, Denon);

    /* Set up file descriptofs for select() */
    fd_set read_fds;
    FD_ZERO(&read_fds);

    /* Add socket fd to monitoring */
    FD_SET(Server.GetSocketFdId(), &read_fds);

    /* Set up select() timeout */
    struct timeval timeout;
    timeout.tv_sec = 5;
    timeout.tv_usec = 0;

    while (!shutDownServer) {
        num_ready_fds = select(Server.GetSocketFdId() + 1, &read_fds, NULL, NULL, &timeout);

        if (num_ready_fds < 0) {
            std::cerr << "select() error" << std::endl;
            std::cout 
            << ", sfd=" << Server.GetSocketFdId() 
            << ", numfds=" << num_ready_fds
            << ", rfds=" << *read_fds.fds_bits
            << std::endl;
        } else if (num_ready_fds == 0) {
            // Select timeout
        } else {
            // Check ready descriptors
            if (FD_ISSET(Server.GetSocketFdId(), &read_fds)) {
                Server.ReceiveMessage();
                Server.SendMessage();
                if (Server.GetCmdCode() == 88) {
                    shutDownServer = true;
                }
            }
        }

        timeout.tv_sec = 5;
        timeout.tv_usec = 0;

        FD_SET(Server.GetSocketFdId(), &read_fds);


        /* Check time to switch off */
        currentTime = time(NULL);
        tm = localtime(&currentTime);

        if ((tm->tm_hour >= tm_off.tm_hour) && 
            (tm->tm_min >= tm_off.tm_min) && 
            (Denon.GetPowerState() == ON) && 
            (Denon.GetAutoPowerOffEnable() == ON)) {
            std::cout << "Automatic Switch Off (" 
                      << tm->tm_hour << "-"
                      << tm->tm_min << "-"
                      << tm->tm_sec << ")"
                      << std::endl;
            system("irsend SEND_ONCE Denon_RC-978 PWR_OFF");
            Denon.SetPower(OFF);
        }

    }

    close(Server.GetSocketFdId());
    return 0;
}

/* Remote control mapping functions */
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
