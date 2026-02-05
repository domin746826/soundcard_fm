#include "buf_param.h"
#include "stm32f4xx_hal.h"
#include <string.h>
#include <stdint.h>
#include <sys/_intsup.h>

int16_t audio_buffer[BUFFER_SIZE];
uint16_t current_position = 0;

_Bool is_playing = 0;

static int16_t left_prev_sample = 0;
static int16_t right_prev_sample = 0;

union {
    uint8_t bytes[4];
    struct {
        int16_t left;
        int16_t right;
    };
} raw_to_lr;


// Tau = 50us, T = 20.83us (1/48k) -> Tau/T ~= 2.40
// y[n] = 3.40 * x[n] - 2.40 * x[n-1]
// 3.40 * 4096 = 13926
// 2.40 * 4096 = 9830
#define PREEMPH_COEFF_CURR 13926
#define PREEMPH_COEFF_PREV 9830
#define PREEMPH_SHIFT 12

static inline int16_t sat_int16(int32_t val) {
    if (val > 32767) return 32767;
    if (val < -32768) return -32768;
    return (int16_t)val;
}

void append_audio_data(uint8_t* pbuf, uint32_t size) {
    int32_t temp_filtered;

    for(int i = 0; i < size; i += 4) {

        for(int j = 0; j < 4; j++) {
            raw_to_lr.bytes[j] = *pbuf++;
        }


        temp_filtered = (int32_t)raw_to_lr.left * PREEMPH_COEFF_CURR - 
                        (int32_t)left_prev_sample * PREEMPH_COEFF_PREV;
        
        left_prev_sample = raw_to_lr.left;

        audio_buffer[current_position++] = sat_int16(temp_filtered >> PREEMPH_SHIFT);

        temp_filtered = (int32_t)raw_to_lr.right * PREEMPH_COEFF_CURR - 
                        (int32_t)right_prev_sample * PREEMPH_COEFF_PREV;
        
        right_prev_sample = raw_to_lr.right;

        audio_buffer[current_position++] = sat_int16(temp_filtered >> PREEMPH_SHIFT);
        
        if(current_position >= BUFFER_SIZE) {
            current_position = 0;
        }
    }
}