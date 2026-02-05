#ifndef BUF_PARAM_H
#define BUF_PARAM_H

#include <stdint.h>

// 4096 samples per channel
#define BUFFER_SIZE 8192  
#define SAMPLE_RATE 48000.0f
#define FREQUENCY 440.0f 

extern int16_t audio_buffer[BUFFER_SIZE];
extern uint16_t current_position;
extern _Bool is_playing;
void append_audio_data(uint8_t* pbuf, uint32_t size);
void start_playing();

#endif
