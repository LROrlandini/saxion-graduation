import time
import board_handler as bh
import data_handler as dh
import helper_module as hm
import numpy as np


def save_data(values, accuracy):
    datapoint = np.append(values, 0)
    if accuracy == 'a':
        dh.write_csv_data(hm.DATA_PATH + 'simon_quad.csv', datapoint)
    elif accuracy == 'b':
        dh.write_csv_data(hm.DATA_PATH + 'simon_square.csv', datapoint)
    elif accuracy == 'c':
        dh.write_csv_data(hm.DATA_PATH + 'simon_led.csv', datapoint)


def main_logic(acc):
    accuracy = acc
    counter = 0
    bh.adc()
    time.sleep(hm.DELAY * 2)
    while counter < 251:
        touch_mtx = bh.read_led_values()
        if touch_mtx[0][0] != 0:
            save_data(touch_mtx.flatten(), accuracy)
        counter += 1
    bh.adc()