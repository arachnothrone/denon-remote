#pragma once


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
