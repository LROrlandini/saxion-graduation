import json
import serial
import time
import numpy as np

WIDTH = 12
HEIGHT = 12

# Individual pixel pair (red & green)
class Pixel:
    def __init__(self, red, green):
        self.red = red
        self.green = green

    def to_byte(self):
        return ((self.green<<4) & 0xF0) | (self.red & 0x0F)


# LED matrix
class LedMatrix:
    def __init__(self, width=WIDTH, height=HEIGHT):
        self.width = width
        self.height = height
        self.matrix = [
            [Pixel(0,0) for _ in range(width)] for _ in range(height)
        ]


# Reads array of values from serial connection.
# Array is uchar JSON 2D format. It gets converted to 1D numpy int.
def read_led_values():
    with serial.Serial('/dev/ttyACM0', 460800) as serial_connection:
        
        led_values = serial_connection.readline().decode('utf-8')
        serial_connection.close()

        if led_values.startswith('LM='):
            try:
                led_values = np.array(json.loads(led_values[3:]), dtype='int16')
            except:
                return np.ones((1, 1), dtype='int16')
            led_values[4][6] -= 45
            #print('TOUCH\n', led_values)
            return led_values
        else:
            return np.zeros((1, 1), dtype='int16')


# Sets LED matrix LEDs on or off according to matrix supplied
def set_matrix(led_matrix):
    with serial.Serial('/dev/ttyACM0', 460800) as serial_connection:
        serial_connection.write(b'Get\r')
        serial_connection.write(b'Set\r')
        for col in range(led_matrix.width):
            bytes_array = []
            for row in range(led_matrix.height):
                bytes_array.append(led_matrix.matrix[col][row].to_byte())
            serial_connection.write(bytes_array)
            time.sleep(0.001)
        serial_connection.close()


def display_all_red():
    mtx = LedMatrix()
    for col in range (WIDTH):
        for row in range (HEIGHT):
            mtx.matrix[col][row].red = 3
    set_matrix(mtx)


def display_all_green():
    mtx = LedMatrix()
    for col in range (WIDTH):
        for row in range (HEIGHT):
            mtx.matrix[col][row].green = 3
    set_matrix(mtx)


def display_clear():
    mtx = LedMatrix()
    set_matrix(mtx)


# Switches LED matrix off.
def clear_matrix(led_matrix):
    for col in range (led_matrix.width):
        for row in range (led_matrix.height):
            led_matrix.matrix[col][row].red = 0
            led_matrix.matrix[col][row].green = 0
    set_matrix(led_matrix)


# Toggle buzzer on or off
def buzz():
    with serial.Serial('/dev/ttyACM0', 460800) as serial_connection:
        serial_connection.write(b'Buz\r')
        serial_connection.close()


# Toggle ADC on or off
def adc():
    with serial.Serial('/dev/ttyACM0', 460800) as serial_connection:
        serial_connection.write(b'Adc\r')
        serial_connection.close()