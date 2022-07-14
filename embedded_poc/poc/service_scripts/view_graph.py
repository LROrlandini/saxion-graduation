import os, signal, sys, time
sys.path.insert(1, os.path.abspath('.'))

from matplotlib import pyplot as plt
import numpy as np
import board_handler


# Clears LED matrix on quit
def signal_handler(signum, frame):
    board_handler.display_clear()
    board_handler.adc()
    exit(1)
signal.signal(signal.SIGINT, signal_handler)


fig = plt.figure(figsize=(10,10))


# Subtracts values by their mean and displays in reactive plot.
def display_graph(values):
    plt.ion()
    plt.imshow(np.reshape(values, (12,12)), vmin = 525, vmax = 625)
    cax = plt.axes([0.85, 0.1, 0.075, 0.8])
    plt.colorbar(cax=cax)
    plt.pause(0.001)
    fig.clear()


board_handler.adc()
time.sleep(1)

while True:
    touch_values = board_handler.read_led_values()
    if touch_values[0][0] != 0:
        display_graph(touch_values)
