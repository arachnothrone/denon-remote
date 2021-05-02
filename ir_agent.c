/*
 * RPi IR-agent
 */

#include <stdio.h>
#include <sys/socket.h>

//#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
//#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>

#define RX_PORT         (19001)
#define RX_BUFFER_SIZE  (1024)


int main(int argc, char **argv)
{
    // CONTROL_COMMAND_T receivedCommand;
    int sockfd;
    char buffer[RX_BUFFER_SIZE];
    char* reply_ok = "OK";
    //struct sockaddr serverAddr, clientAddr;
    struct sockaddr_in serverAddr, clientAddr;
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        perror("socket creation failed");
        exit(EXIT_FAILURE);
    }
    
    memset(&serverAddr, 0, sizeof(serverAddr));
    memset(&clientAddr, 0, sizeof(clientAddr));

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
        printf("Received request: %s\n", buffer);

        char rcvCmd;
        rcvCmd = atoi(&buffer[4]);
        printf("Decoded command: %d\n", rcvCmd);

        switch (rcvCmd)
        {
        case 1:
            /* PWR */
            break;
        case 2:
            /* VOLUMEUP */
            system("irsend SEND_ONCE Denon_RC-917 KEY_VOLUMEUP");
            break;
        case 3:
            /* VOLUMEDOWN */
            system("irsend SEND_ONCE Denon_RC-917 KEY_VOLUMEDOWN");
            break;
        
        default:
            break;
        }
        
        sendto(sockfd, (const char *)reply_ok, strlen(reply_ok), MSG_CONFIRM, (const struct sockaddr *) &clientAddr, len);
        printf("Response sent.\n"); 
    }
          
    return 0;
}
