/*
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

#define RX_PORT         (19001)
#define RX_BUFFER_SIZE  (1024)

typedef enum
{
    PWRISON,
    PWRISOFF,
} STATE_POWER;

typedef enum
{
    STANDARD,
    DIRECT,
    STEREO,
    CH5CH7
} STATE_MODE;

typedef struct MEM_STATE_T_TAG
{
    int         volume;
    STATE_MODE  stereoMode;
    STATE_POWER powerState;
} MEM_STATE_T;


int main(int argc, char **argv)
{
    // CONTROL_COMMAND_T receivedCommand;
    int sockfd;
    char buffer[RX_BUFFER_SIZE];
    char* reply_ok = "OK";
    struct sockaddr_in serverAddr, clientAddr;
    MEM_STATE_T denonState;

    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        perror("socket creation failed");
        exit(EXIT_FAILURE);
    }
    
    memset(&serverAddr, 0, sizeof(serverAddr));
    memset(&clientAddr, 0, sizeof(clientAddr));
    memset(&denonState, 0, sizeof(denonState));

    serverAddr.sin_family = AF_INET; // IP v4
    serverAddr.sin_addr.s_addr = INADDR_ANY;
    serverAddr.sin_port = htons(RX_PORT);

    if (bind(sockfd, (const struct sockaddr *)&serverAddr, sizeof(serverAddr)) < 0)
    {
        perror("UDP port binding failed");
        exit(EXIT_FAILURE);
    }

    int len, n;
  
    len = sizeof(clientAddr);
  
    while(1)
    {
        n = recvfrom(sockfd, (char *)buffer, RX_BUFFER_SIZE, MSG_WAITALL, (struct sockaddr *) &clientAddr, &len);
        buffer[n] = '\0';
        char clientAddrString[INET_ADDRSTRLEN];
        printf("Received request: %s [%s:%0d]\n", 
            buffer, inet_ntop(AF_INET, &clientAddr.sin_addr.s_addr, clientAddrString, sizeof(clientAddrString)), ntohs(clientAddr.sin_port));

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
        printf("Decoded command: %d\n", rcvCmd);

        switch (rcvCmd)
        {
            case 1:
                /* DIMMER */
                system("irsend SEND_ONCE Denon_RC-978 DIMMER");
                break;
            case 2:
                /* VOLUMEUP */
                system("irsend SEND_ONCE Denon_RC-978 KEY_VOLUMEUP");
                break;
            case 3:
                /* VOLUMEDOWN */
                system("irsend SEND_ONCE Denon_RC-978 KEY_VOLUMEDOWN");
                break;
            case 4:
                /* PWR_ON */
                system("irsend SEND_ONCE Denon_RC-978 PWR_ON");
                break;
            case 5:
                /* PWR_OFF */
                system("irsend SEND_ONCE Denon_RC-978 PWR_OFF");
                break;
            case 6:
                /* MUTE */
                system("irsend SEND_ONCE Denon_RC-978 KEY_MUTING");
                break;
            case 7:
                /* 5CH7CHSTEREO */
                system("irsend SEND_ONCE Denon_RC-978 5CH7CHSTEREO");
                break;
            case 8:
                /* DSPSIMULATION */
                system("irsend SEND_ONCE Denon_RC-978 DSPSIMULATION");
                break;
            case 9:
                /* STANDARD */
                system("irsend SEND_ONCE Denon_RC-978 STANDARD");
                break;
            case 10:
                /* CINEMA */
                system("irsend SEND_ONCE Denon_RC-978 CINEMA");
                break;
            case 11:
                /* MUSIC */
                system("irsend SEND_ONCE Denon_RC-978 MUSIC");
                break;
            case 12:
                /* DIRECT */
                system("irsend SEND_ONCE Denon_RC-978 DIRECT");
                break;
            case 13:
                /* STEREO */
                system("irsend SEND_ONCE Denon_RC-978 STEREO");
                break;
            case 14:
                /* VIRTSURROUND */
                system("irsend SEND_ONCE Denon_RC-978 VIRTSURROUND");
                break;
            case 15:
                /* INPUT_MODE */
                system("irsend SEND_ONCE Denon_RC-978 INPUT_MODE");
                break;
            case 16:
                /* INPUT_ANALOG */
                system("irsend SEND_ONCE Denon_RC-978 INPUT_ANALOG");
                break;
            case 17:
                /* INPUT_EXTIN */
                system("irsend SEND_ONCE Denon_RC-978 INPUT_EXTIN");
                break;
            default:
                break;
        }
        
        // sendto(sockfd, (const char *)reply_ok, strlen(reply_ok), MSG_CONFIRM, (const struct sockaddr *) &clientAddr, len);
        char replBuf[10];
        sprintf(replBuf, "Volume: %d", denonState.volume);
        sendto(sockfd, replBuf, strlen(replBuf), MSG_CONFIRM, (const struct sockaddr *) &clientAddr, len);
        printf("Response sent.\n"); 
    }
          
    return 0;
}

/// 

