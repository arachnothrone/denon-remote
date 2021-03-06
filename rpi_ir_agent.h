#pragma once

#include <string>
#include <map>
#include <exception>

#define RX_PORT         (19001)
#define RX_BUFFER_SIZE  (1024)
#define CMD_ARG_SIZE    (2)
#define VOL_MAX_LIMIT   (-15)
#define VOL_MIN_LIMIT   (-70)
#define TS_BUF_SIZE     (19)

#ifdef __APPLE__
//    MSG_EOR         0x8             /* data completes record */ 
// or MSG_EOF         0x100           /* data completes connection */
#define SOCK_SND_FLAG MSG_EOR
#else
// MSG_CONFIRM
#define SOCK_SND_FLAG (0x800)
#endif

// RX Message
#define RXMSGPREF           0
#define RXMSGPREFSZ         3
#define RXMSGCMDCODE        3
#define RXMSGCMDCODESZ      2
#define RXMSGCMDDESCR       5
#define RXMSGCMDDESCRSZ     11
#define RXMSGCMDPARVAL      16
#define RXMSGCMDPARVALSZ    2

typedef enum
{
    OFF,
    ON
} STATE_BINARY;

typedef enum
{
    CH5CH7,
    DSPSIM,
    STANDARD, 
    CINEMA,
    MUSIC, 
    DIRECT,
    STEREO,
    VIRTSURRND,
} STATE_MODE;

typedef enum
{
    INPUTMODE,
    INPUTANALOG,
    INPUTEXTIN
} STATE_INPUT;

typedef enum
{
    LEVEL0,     // Brightness Max
    LEVEL1,     // Brightness Med
    LEVEL2,     // Brightness Min
    LEVEL3      // Screen off
} STATE_DIM;

typedef struct MEM_STATE_T_TAG
{
    int             volume;
    STATE_MODE      stereoMode;
    STATE_BINARY    power;
    STATE_BINARY    mute;
    STATE_DIM       dimmer;
    STATE_INPUT     input;
} MEM_STATE_T;

struct RX_MSG_T {
    std::string msgPrefix;
    int         cmdCode;
    std::string cmdDescription;
    uint8_t     cmdParamValue;
};

struct TX_MSG_T {
    ;
};

typedef enum {
    CMD_GETSTATE,
    CMD_DIMMER, 
    CMD_KEY_VOLUMEUP, 
    CMD_KEY_VOLUMEDOWN, 
    CMD_PWR_ON,
    CMD_PWR_OFF,
    CMD_KEY_MUTING,
    CMD_CH5CH7STEREO,
    CMD_DSPSIMULATION,
    CMD_STANDARD,
    CMD_CINEMA, 
    CMD_MUSIC,
    CMD_DIRECT,
    CMD_STEREO,
    CMD_VIRTSURROUND,
    CMD_INPUT_MODE,
    CMD_INPUT_ANALOG,
    CMD_INPUT_EXTIN,
    CMD_INCREASEVOL, 
    CMD_DECREASEVOL, 
    CMD_SERVERSTOP = 40,
    CMD_CALIBRATE_VOL = 99
} AVRCMD_E;

class Denon {
public:
    Denon();
    void UpdateDimmer();
    void VolumeChangeDb(int dbDelta);
    void SetPower(STATE_BINARY pwr);
    void UpdateMute();
    void SetStereoMode(STATE_MODE mode);
    void SetInput(STATE_INPUT input);
    void PrintState();
    std::string SerializeDenonState();
private:
    int             _volume;
    STATE_MODE      _stereoMode;
    STATE_BINARY    _power;
    STATE_BINARY    _mute;
    STATE_DIM       _dimmer;
    STATE_INPUT     _input;
};

using CmdExecutor = void (*)(Denon& dstate);

void FuncDimmer(Denon& dState);
void FuncVolumeUp(Denon& dState);
void FuncVolumeDown(Denon& dState);
void FuncPowerOn(Denon& dState);
void FuncPowerOff(Denon& dState);
void FuncMuting(Denon& dState);
void FuncSoundModeStereo5ch7ch(Denon& dState);
void FuncSoundModeDspSimulation(Denon& dState);
void FuncSoundModeStandard(Denon& dState);
void FuncSoundModeCinema(Denon& dState);
void FuncSoundModeMusic(Denon& dState);
void FuncSoundModeDirect(Denon& dState);
void FuncSoundModeStereo(Denon& dState);
void FuncSoundModeVirtSurround(Denon& dState);
void FuncInputMode(Denon& dState);
void FuncInputAnalog(Denon& dState);
void FuncInputExtIn(Denon& dState);

class SocketConnection {
public:
    SocketConnection(const int rxport);
    int Bind();
    std::string Recv();
    void Send(const std::string msgString, const int msgStrSize);
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
    IRServer(const int rxport, Denon& dstate);
    void    Deserialize(const std::string& msg);
    void    Serialize();
    bool    ReceiveMessage();
    bool    SendMessage();
    int     GetCmdCode();
    bool    SendIrCommand(int commandCode);
private:
    RX_MSG_T    _rxMessage;
    TX_MSG_T    _txMessage;
    char        rawMessage[RX_BUFFER_SIZE];
    Denon&      _denonState;
    const std::map<int, std::pair<const std::string, CmdExecutor>> _AVRCMDMAP = {
        {CMD_DIMMER, std::make_pair("DIMMER", &FuncDimmer)},
        {CMD_KEY_VOLUMEUP, std::make_pair("KEY_VOLUMEUP", &FuncVolumeUp)}, 
        {CMD_KEY_VOLUMEDOWN, std::make_pair("KEY_VOLUMEDOWN", &FuncVolumeDown)}, 
        {CMD_PWR_ON, std::make_pair("PWR_ON", &FuncPowerOn)}, 
        {CMD_PWR_OFF, std::make_pair("PWR_OFF", &FuncPowerOff)}, 
        {CMD_KEY_MUTING, std::make_pair("KEY_MUTING", &FuncMuting)}, 
        {CMD_CH5CH7STEREO, std::make_pair("5CH7CHSTEREO", &FuncSoundModeStereo5ch7ch)}, 
        {CMD_DSPSIMULATION, std::make_pair("DSPSIMULATION", &FuncSoundModeDspSimulation)}, 
        {CMD_STANDARD, std::make_pair("STANDARD", &FuncSoundModeStandard)}, 
        {CMD_CINEMA, std::make_pair("CINEMA", &FuncSoundModeCinema)}, 
        {CMD_MUSIC,std::make_pair( "MUSIC", &FuncSoundModeMusic)}, 
        {CMD_DIRECT, std::make_pair("DIRECT", &FuncSoundModeDirect)}, 
        {CMD_STEREO, std::make_pair("STEREO", &FuncSoundModeStereo)}, 
        {CMD_VIRTSURROUND, std::make_pair("VIRTSURROUND", &FuncSoundModeVirtSurround)}, 
        {CMD_INPUT_MODE, std::make_pair("INPUT_MODE", &FuncInputMode)}, 
        {CMD_INPUT_ANALOG, std::make_pair("INPUT_ANALOG", &FuncInputAnalog)}, 
        {CMD_INPUT_EXTIN, std::make_pair("INPUT_EXTIN", &FuncInputExtIn)}
    };
};

void getTimeStamp(char* pTimeStamp, int buffSize);
