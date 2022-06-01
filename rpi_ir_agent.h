#pragma once

#include <string>

#define RX_PORT         (19001)
#define RX_BUFFER_SIZE  (1024)
#define CMD_ARG_SIZE    (2)
#define VOL_MAX_LIMIT   (-15)

#ifdef __APPLE__
//    MSG_EOR         0x8             /* data completes record */ 
// or MSG_EOF         0x100           /* data completes connection */
#define SOCK_SND_FLAG MSG_EOR
#else
// MSG_CONFIRM
#define SOCK_SND_FLAG (0x800)
#endif

// RX Message
#define RXMSGPREF        0
#define RXMSGPREFSZ        3
#define RXMSGCMDCODE     3
#define RXMSGCMDCODESZ     2
#define RXMSGCMDDESCR    5
#define RXMSGCMDDESCRSZ    11
#define RXMSGCMDPARVAL   16
#define RXMSGCMDPARVALSZ   2


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

void getTimeStamp(char* pTimeStamp);
