import time
import board_handler as bh
import data_handler as dh
import helper_module as hm
import numpy as np


def dg_get_input(round, accuracy):
    for pos in round:
        counter = 0
        #bh.buzz()
        while counter < 5:
            touch_mtx = bh.read_led_values()
            if touch_mtx[0][0] != 0:
                if touch_mtx[0][0] == 1:
                    #bh.buzz()
                    bh.adc()
                    dh.delete_bad_csv_data(hm.databases[accuracy - 1])
                    exit(1)
                if counter > 0:
                    datapoint = np.append(touch_mtx.flatten(), pos)
                    dh.write_csv_data(hm.databases[accuracy - 1], datapoint)
                counter += 1
        #bh.buzz()
        user_mtx = hm.fill_matrix_pos(pos, accuracy, False)
        bh.set_matrix(user_mtx)
        time.sleep(hm.DELAY)
        bh.display_clear()


def ht_get_input(round, accuracy):
    answer = []
    for _ in range(len(round)):
        predicted = 0
        while predicted == 0:
            touch_mtx = bh.read_led_values()
            if touch_mtx[0][0] != 0:
                adc_readings = touch_mtx.flatten()
                predicted = hm.predict(adc_readings, accuracy)
                print("predicted", predicted)
        answer.append(predicted)
        user_mtx = hm.fill_matrix_pos(int(predicted), accuracy, False)
        bh.set_matrix(user_mtx)
        time.sleep(hm.DELAY)
        bh.display_clear()
    return answer


def play_round(round, accuracy, mode):
    print("ROUND", round)
    for pos in round:
        game_mtx = hm.fill_matrix_pos(pos, accuracy, True)
        #bh.buzz()
        bh.set_matrix(game_mtx)
        time.sleep(hm.DELAY)
        #bh.buzz()
        bh.display_clear()
        time.sleep(hm.DELAY)
    bh.adc()
    time.sleep(hm.DELAY / 2)
    if mode == 'dg':
        dg_get_input(round, accuracy)
        bh.adc()
        return True
    elif mode == 'ht':
        user_answer = ht_get_input(round, accuracy)
        bh.adc()
        if user_answer == round:
            return True
        else:
            return False


def main_logic(md, acc):
    level = 1
    mode = md
    accuracy = acc
    hm.load_models_and_databases()

    if mode == 'ht':
        hm.load_scaler(accuracy)

    correct = True
    while correct:
        if level < 10:
            timer_mtx = bh.display_number(level)
            bh.countdown_line(timer_mtx, 0.1)
            current_round = hm.generate_round(level, accuracy)
            correct = play_round(current_round, accuracy, mode)
            level += 1
        else:
            current_round = None
            level = 1
            return True
    current_round = None
    level = 1
    return False
    
