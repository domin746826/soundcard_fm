import math
import time
import serial

# Constants
SAMPLE_RATE = 48000
FREQ = 440.0
BAUD = 500000

def main():
    try:
        # Open serial port
        uart = serial.Serial(
            port='/dev/ttyUSB1',
            baudrate=BAUD,
            bytesize=8,
            parity='N',
            stopbits=1,
            timeout=None
        )
        
        phase = 0.0
        step = 2.0 * math.pi * FREQ / SAMPLE_RATE
        
        while True:
            # Sine wave generation for 440Hz
            s = math.sin(phase)  # -1 .. +1
            sample = int(s * 127.0 + 128.0)  # u8, 128 = zero
            
            # Send sample over UART
            uart.write(bytes([sample]))
            
            # Phase increment
            phase += step
            if phase >= 2.0 * math.pi:
                phase -= 2.0 * math.pi
            
            # Calculate proper timing for sample rate
            time.sleep(1.0 / SAMPLE_RATE)  # Sleep for one sample period
            
    except serial.SerialException as e:
        print(f"Serial port error: {e}")
        return 1
    except KeyboardInterrupt:
        print("Interrupted by user")
        return 0
    finally:
        if 'uart' in locals():
            uart.close()

if __name__ == "__main__":
    main()