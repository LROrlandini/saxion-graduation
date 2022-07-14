import time
import board_handler as bh
import data_handler as dh
import helper_module as hm
import numpy as np


def get_input(round, accuracy):
    counter = 0
    while counter <= 51:
        touch_mtx = bh.read_led_values()
        if touch_mtx[0][0] != 0:
            if touch_mtx[0][0] == 1:
                dh.delete_bad_csv_data(hm.databases[accuracy-1])
                exit(1)
            datapoint = np.append(touch_mtx.flatten(), round)
            dh.write_csv_data(hm.databases[accuracy-1], datapoint)
            counter += 1
    user_mtx = hm.fill_matrix_pos(round, accuracy, False)
    bh.set_matrix(user_mtx)
    time.sleep(hm.DELAY)
    bh.display_clear()


def play_round(round, accuracy):
    print("ROUND", round)

    game_mtx = hm.fill_matrix_pos(round, accuracy, True)
    bh.set_matrix(game_mtx)
    time.sleep(hm.DELAY)
    bh.display_clear()
    bh.adc()
    time.sleep(hm.DELAY)
    get_input(round, accuracy)
    bh.adc()


def main_logic(acc):
    accuracy = acc
    hm.load_models_and_databases()

    while True:
        position = input("Enter position to train:\n")
        current_round = int(position)
        play_round(current_round, accuracy)
        current_round = None
