/**
 * RPi Denon IR-agent
 */

#include <stdio.h>
#include <sys/socket.h>

#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <time.h>

#define RX_PORT         (19001)
#define RX_BUFFER_SIZE  (1024)
#define CMD_ARG_SIZE    (2)
#define VOL_MAX_LIMIT   (-15)

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

/**
 * Declarations
 */
char* getTimeStamp(void);
STATE_DIM UdpateDimmerState(const MEM_STATE_T* pDenonState);
STATE_BINARY UpdateMuteState(const MEM_STATE_T* pDenonState);
void SerializeDenonState(const MEM_STATE_T* pDenonState, char* buffer);
void DenonStateInit(MEM_STATE_T* pDenonState);
void SetMinimumVolume(MEM_STATE_T* pDenonState, double timeIntervalSec);
void SetVolumeTo(MEM_STATE_T* pDenonState, int value);


/**
 * Main function
 */
int main(int argc, char **argv)
{
    // CONTROL_COMMAND_T receivedCommand;
    int sockfd;
    char buffer[RX_BUFFER_SIZE];
    char cmdArg[CMD_ARG_SIZE];
    // char* reply_ok = "OK";
    struct sockaddr_in serverAddr, clientAddr;
    // struct timeval timestamp;
    MEM_STATE_T denonState;
    int deltaVol = 0;


    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        perror("socket creation failed");
        exit(EXIT_FAILURE);
    }
    
    memset(&serverAddr, 0, sizeof(serverAddr));
    memset(&clientAddr, 0, sizeof(clientAddr));
    memset(&denonState, 0, sizeof(denonState));

    DenonStateInit(&denonState);

    serverAddr.sin_family = AF_INET; // IP v4
    serverAddr.sin_addr.s_addr = INADDR_ANY;
    serverAddr.sin_port = htons(RX_PORT);

    if (bind(sockfd, (const struct sockaddr *)&serverAddr, sizeof(serverAddr)) < 0)
    {
        perror("UDP port binding failed");
        exit(EXIT_FAILURE);
    }

    unsigned int len, n;
  
    len = sizeof(clientAddr);
  
    /**
     * Main application loop
     */
    char* time_stmp;
    
    while(1)
    {
        // Receive command into a buffer, e.g.:
        // CMDxxDESCRyy
        // CMD      - mandatory prefix
        // xx       - command code (required)
        // DESCR    - command description (required)
        // yy       - command parameter value (required only for specific commands)
        n = recvfrom(sockfd, (char *)buffer, RX_BUFFER_SIZE, MSG_WAITALL, (struct sockaddr *) &clientAddr, &len);
        buffer[n] = '\0';
        char clientAddrString[INET_ADDRSTRLEN];
        
        time_stmp = getTimeStamp();
        
        if (time_stmp == NULL)
        {
            printf("Can't allocate timestamp buffer!!!");
        }
        else
        {
            printf("%s Received request: %s [%s:%0d]\n", time_stmp, 
                buffer, inet_ntop(AF_INET, &clientAddr.sin_addr.s_addr, clientAddrString, sizeof(clientAddrString)), ntohs(clientAddr.sin_port));
            free(time_stmp);
        }

        char rcvCmd;
        //rcvCmd = atoi(&buffer[3]) * 10 + atoi(&buffer[4]);
        // int i;
        // for (i = 0; i < n; i++)
        // {
        //     printf(": %d - %d (%c), addr=%d\n", i, buffer[i], buffer[i], buffer + i * sizeof(int));
        // }
        char sym1, sym2;
        sym1 = buffer[3];
        sym2 = buffer[4];
        // printf("===: %c, %c\n", sym1, sym2);
        // printf("===: %d, %d\n", sym1, sym2);
        // printf("===: %d, %d\n", atoi(&sym1), atoi(&sym2));
        // printf("===: %d, %d\n", (int)sym1 - 48, (int)sym2 - 48);
        // rcvCmd = atoi(&buffer[4]) + atoi(&buffer[3]);
        // char z = '0';
        // printf("atoi 0: %d", atoi(&z));
        rcvCmd = (int)(sym1-48) * 10 + (int)(sym2-48);
        //printf("Decoded command: %d\n", rcvCmd);

        switch (rcvCmd)
        {
            case 1:
                /* DIMMER */
                system("irsend SEND_ONCE Denon_RC-978 DIMMER");
                denonState.dimmer = UdpateDimmerState(&denonState);
                break;
            case 2:
                /* VOLUMEUP */
                system("irsend SEND_ONCE Denon_RC-978 KEY_VOLUMEUP");
                denonState.volume++;
                break;
            case 3:
                /* VOLUMEDOWN */
                system("irsend SEND_ONCE Denon_RC-978 KEY_VOLUMEDOWN");
                denonState.volume--;
                break;
            case 4:
                /* PWR_ON */
                system("irsend SEND_ONCE Denon_RC-978 PWR_ON");
                denonState.power = ON;
                break;
            case 5:
                /* PWR_OFF */
                system("irsend SEND_ONCE Denon_RC-978 PWR_OFF");
                denonState.power = OFF;
                break;
            case 6:
                /* MUTE */
                system("irsend SEND_ONCE Denon_RC-978 KEY_MUTING");
                denonState.mute = UpdateMuteState(&denonState);
                break;
            case 7:
                /* 5CH7CHSTEREO */
                system("irsend SEND_ONCE Denon_RC-978 5CH7CHSTEREO");
                denonState.stereoMode = CH5CH7;
                break;
            case 8:
                /* DSPSIMULATION */
                system("irsend SEND_ONCE Denon_RC-978 DSPSIMULATION");
                denonState.stereoMode = DSPSIM;
                break;
            case 9:
                /* STANDARD */
                system("irsend SEND_ONCE Denon_RC-978 STANDARD");
                denonState.stereoMode = STANDARD;
                break;
            case 10:
                /* CINEMA */
                system("irsend SEND_ONCE Denon_RC-978 CINEMA");
                denonState.stereoMode = CINEMA;
                break;
            case 11:
                /* MUSIC */
                system("irsend SEND_ONCE Denon_RC-978 MUSIC");
                denonState.stereoMode = MUSIC;
                break;
            case 12:
                /* DIRECT */
                system("irsend SEND_ONCE Denon_RC-978 DIRECT");
                denonState.stereoMode = DIRECT;
                break;
            case 13:
                /* STEREO */
                system("irsend SEND_ONCE Denon_RC-978 STEREO");
                denonState.stereoMode = STEREO;
                break;
            case 14:
                /* VIRTSURROUND */
                system("irsend SEND_ONCE Denon_RC-978 VIRTSURROUND");
                denonState.stereoMode = VIRTSURRND;
                break;
            case 15:
                /* INPUT_MODE */
                system("irsend SEND_ONCE Denon_RC-978 INPUT_MODE");
                denonState.input = INPUTMODE;
                break;
            case 16:
                /* INPUT_ANALOG */
                system("irsend SEND_ONCE Denon_RC-978 INPUT_ANALOG");
                denonState.input = INPUTANALOG;
                break;
            case 17:
                /* INPUT_EXTIN */
                system("irsend SEND_ONCE Denon_RC-978 INPUT_EXTIN");
                denonState.input = INPUTEXTIN;
                break;
            case 18:
                /* INCREASEVOL by n dB */
                cmdArg[0] = buffer[16];
                cmdArg[1] = buffer[17];
                deltaVol = atoi(cmdArg);
                SetVolumeTo(&denonState, denonState.volume + deltaVol);
                break;
            case 19:
                /* DECREASEVOL by n dB */
                cmdArg[0] = buffer[16];
                cmdArg[1] = buffer[17];
                deltaVol = atoi(cmdArg);
                SetVolumeTo(&denonState, denonState.volume - deltaVol);
                break;
            case 99:
                /* CALIBRATE_VOL */
                SetMinimumVolume(&denonState, 3.75); // 3.75 sec - time interval of sending continuous volume down command:
                                                    // ~ 75 ms / 1 dB, lower bound = -70 dB => from -20 to -70 (50 dB): 3750 ms
                SetVolumeTo(&denonState, -40);      // set calibrated level to -40 dB, from -70 it takes ~9 sec
                                                    // Calibration cycle takes ~14 sec
                break;
            default:
                break;
        }
        
        // sendto(sockfd, (const char *)reply_ok, strlen(reply_ok), MSG_CONFIRM, (const struct sockaddr *) &clientAddr, len);
        char replBuf[sizeof(denonState)];
        SerializeDenonState(&denonState, replBuf);
        //sprintf(replBuf, "Volume: %d", denonState.volume);
        sendto(sockfd, replBuf, strlen(replBuf), MSG_CONFIRM, (const struct sockaddr *) &clientAddr, len);
        printf("%s Response sent: power=%d, vol=%d, mode=%d, input=%d, mute=%d, dimmer=%d [%s:%0d]\n", getTimeStamp(), 
            denonState.power, denonState.volume, denonState.stereoMode, 
            denonState.input, denonState.mute, denonState.dimmer, 
            inet_ntop(AF_INET, &clientAddr.sin_addr.s_addr, clientAddrString, sizeof(clientAddrString)), 
            ntohs(clientAddr.sin_port));
    }
          
    return 0;
}

/// 
STATE_DIM UdpateDimmerState(const MEM_STATE_T* pDenonState)
{
    STATE_DIM updatedState = LEVEL0;
    if (pDenonState->dimmer < LEVEL3)
    {
        updatedState = pDenonState->dimmer + 1;
    }
    else
    {
        updatedState = LEVEL0;
    }

    return updatedState;
}

STATE_BINARY UpdateMuteState(const MEM_STATE_T* pDenonState)
{
    STATE_BINARY updatedState = OFF;
    if (pDenonState->mute == OFF)
    {
        updatedState = ON;
    }

    return updatedState;
}

void SerializeDenonState(const MEM_STATE_T* pDenonState, char* buffer)
{
    sprintf(buffer, "%d,%d,%d,%d,%d,%d", 
        pDenonState->power,
        pDenonState->volume,
        pDenonState->mute,
        pDenonState->stereoMode, 
        pDenonState->input, 
        pDenonState->dimmer
    );
}

void DenonStateInit(MEM_STATE_T* pDenonState)
{
    pDenonState->power = OFF;
    pDenonState->volume = -40;
    pDenonState->mute = OFF;
    pDenonState->stereoMode = STANDARD;
    pDenonState->input = INPUTMODE;
    pDenonState->dimmer = LEVEL0;
}

void SetMinimumVolume(MEM_STATE_T* pDenonState, double timeIntervalSec)
{
    //struct timespec ts = {.tv_sec = 7, .tv_nsec = 5e8};         // for 4.5 sec delay
    struct timespec ts = {.tv_sec = (int) timeIntervalSec, .tv_nsec = (timeIntervalSec - ((int) timeIntervalSec)) * 1e9};
    system("irsend SEND_START Denon_RC-978 KEY_VOLUMEDOWN");
    nanosleep(&ts, NULL);
    system("irsend SEND_STOP Denon_RC-978 KEY_VOLUMEDOWN");
    ts.tv_sec = 0;
    ts.tv_nsec = 5e8;
    nanosleep(&ts, NULL);
    system("irsend SEND_ONCE Denon_RC-978 KEY_VOLUMEUP");
    pDenonState->volume = -70;
}

void SetVolumeTo(MEM_STATE_T* pDenonState, int value)
{
    int i, deltaVol;
    char command[50];
    struct timespec ts = {.tv_sec = 0, .tv_nsec = 80e6};         // 80 ms (was 120 ms = 12e7) delay
    
    if (pDenonState->volume > value)
    {
        strcpy(command, "irsend SEND_ONCE Denon_RC-978 KEY_VOLUMEDOWN");
    }
    else
    {
        strcpy(command, "irsend SEND_ONCE Denon_RC-978 KEY_VOLUMEUP");
    }

    deltaVol = abs(abs(pDenonState->volume) - abs(value));
    
    nanosleep(&ts, NULL);

    for (i = 0; i < deltaVol; i++)
    {
        if (pDenonState->volume >= VOL_MAX_LIMIT)
        {
            printf("SetVolumeTo: Maximum reached (%d dB)\n", VOL_MAX_LIMIT);
            break;
        }
        else
        {
            system(command);
            printf("Executing: %s (%d)\n", command, strlen(command));

            // 100 ms pause between two steps
            nanosleep(&ts, NULL);
        }
    }

    pDenonState->volume = value;
    printf("SetVolumeTo: set to %d\n", pDenonState->volume);
}

/**
 * @brief Get the Time Stamp
 * 
 * @return char* 
 */
char* getTimeStamp(void)
{
    char* pTimeStamp;
    time_t currentTime;
    struct tm* tm;

    currentTime = time(NULL);
    tm = localtime(&currentTime);
    pTimeStamp = (char*)malloc(sizeof(char) * 16);
    sprintf(pTimeStamp, "%04d-%02d-%02d %02d:%02d:%02d", tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday, tm->tm_hour, tm->tm_min, tm->tm_sec);

    return pTimeStamp;
}
