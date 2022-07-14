import os, sys
sys.path.insert(1, os.path.abspath('.'))

import serial


with serial.Serial('/dev/ttyACM0', 460800) as serial_connection:
    serial_connection.write(b'Buz\r')
    serial_connection.close()