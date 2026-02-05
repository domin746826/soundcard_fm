// DEPRECATED it was used for transmitting sound over serial to FPGA

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <pulse/simple.h>
#include <pulse/error.h>
#include <termios.h>
#include <stdint.h>
#include <math.h>

// KONFIGURACJA
#define SERIAL_PORT "/dev/ttyUSB1" 
#define SAMPLE_RATE 48000
#define BUFFER_SIZE 64  

// PREEMFAZA 50us 
#define PREEMPH_TAU 50e-6   
#define PREEMPH_ALPHA (PREEMPH_TAU * SAMPLE_RATE) 

int setup_serial(const char *portname) {
    int fd = open(portname, O_RDWR | O_NOCTTY | O_SYNC);
    if (fd < 0) {
        fprintf(stderr, "Błąd otwarcia %s: %s\n", portname, strerror(errno));
        return -1;
    }

    struct termios tty;
    if (tcgetattr(fd, &tty) != 0) {
        fprintf(stderr, "Błąd tcgetattr: %s\n", strerror(errno));
        return -1;
    }


    cfsetospeed(&tty, 480000);
    cfsetispeed(&tty, 480000);

    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8; // 8-bit chars
    tty.c_iflag &= ~IGNBRK;                     // disable break processing
    tty.c_lflag = 0;                            // no signaling chars, no echo, no canonical processing
    tty.c_oflag = 0;                            // no remapping, no delays
    tty.c_cc[VMIN]  = 0;                        // read doesn't block
    tty.c_cc[VTIME] = 5;                        // 0.5 seconds read timeout

    tty.c_iflag &= ~(IXON | IXOFF | IXANY); // shut off xon/xoff ctrl
    tty.c_cflag |= (CLOCAL | CREAD);        // ignore modem controls, enable reading
    tty.c_cflag &= ~(PARENB | PARODD);      // shut off parity
    tty.c_cflag &= ~CSTOPB;
    tty.c_cflag &= ~CRTSCTS;
    if (tcsetattr(fd, TCSANOW, &tty) != 0) {
        fprintf(stderr, "Błąd tcsetattr: %s\n", strerror(errno));
        return -1;
    }
    return fd;
}


static int32_t preemph_prev_input = 0;

int32_t preemphasis_filter(int32_t input) {
    static const float alpha = PREEMPH_ALPHA / (1.0f + PREEMPH_ALPHA);
    
    int32_t output = input - (int32_t)(alpha * preemph_prev_input);
    
    preemph_prev_input = input;
    
    return output;
}

int main(int argc, char*argv[]) {

    static const pa_sample_spec ss = {
        .format = PA_SAMPLE_S24_32LE,
        .rate = SAMPLE_RATE,
        .channels = 1
    };

    pa_buffer_attr ba;
    ba.maxlength = (uint32_t) -1;
    ba.tlength = (uint32_t) -1;
    ba.prebuf = (uint32_t) -1;
    ba.minreq = (uint32_t) -1;
    ba.fragsize = BUFFER_SIZE * sizeof(int32_t);

    pa_simple *s = NULL;
    int error;

    int serial_fd = setup_serial(SERIAL_PORT);
    if (serial_fd < 0) return 1;


    s = pa_simple_new(NULL, "AudioToSerial", PA_STREAM_RECORD, "SerialSink.monitor", "record", &ss, NULL, &ba, &error);
    
    if (!s) {
        fprintf(stderr, "pa_simple_new() failed: %s\n", pa_strerror(error));
        return 1;
    }

    fprintf(stderr, "Program uruchomiony. Przesyłanie 48kHz 24bit -> preemfaza 50us -> 8bit UART...\n");

    int32_t input_buffer[BUFFER_SIZE];
    uint8_t output_buffer[BUFFER_SIZE];

    while (1) {
        if (pa_simple_read(s, input_buffer, sizeof(input_buffer), &error) < 0) {
            fprintf(stderr, "pa_simple_read() failed: %s\n", pa_strerror(error));
            break;
        }


        const int32_t GAIN = 1; 

        for (int i = 0; i < BUFFER_SIZE; i++) {
            int32_t sample = input_buffer[i];

            sample = preemphasis_filter(sample);
            sample = sample * GAIN;

            int8_t val = (sample >> 16); 
            
            output_buffer[i] = (uint8_t)(val + 128);
        }

        write(serial_fd, output_buffer, BUFFER_SIZE);
    }

    if (s) pa_simple_free(s);
    close(serial_fd);
    return 0;
}