import os, sys

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  # Disable TensorFlow messages
sys.path.insert(1, os.path.abspath('.'))

import time, random
import board_handler as bh
import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.preprocessing import MinMaxScaler

if os.getlogin() == 'localuser':
    DATA_PATH = '/home/localuser/aemics_board/30017400/src01/data_handler/data/'
elif os.getlogin() == 'luciano':
    DATA_PATH = '/home/luciano/aemics_board/30017400/src01/data_handler/data/'

WIDTH = 12
HEIGHT = 12
DELAY = 0.5
PROB_THRESHOLD = 0.20

models = []
databases = []
scaler = None


def load_models_and_databases():
    models.append(tf.keras.models.load_model('nn_quad'))
    models.append(tf.keras.models.load_model('nn_square'))
    models.append(tf.keras.models.load_model('nn_led'))
    databases.append(DATA_PATH + 'simon_quad.csv')
    databases.append(DATA_PATH + 'simon_square.csv')
    databases.append(DATA_PATH + 'simon_led.csv')


def load_scaler(accuracy):
    global scaler
    scaler = None
    scaler = MinMaxScaler()
    data = pd.read_csv(databases[accuracy-1])
    data = data.sample(frac=1, random_state=42).reset_index(drop=True)
    for i in range (0, 144):
        indexes = data[ (data[str(i)] < 450) | (data[str(i)] > 650) ].index
        data.drop(indexes, inplace=True)
    scaler.fit_transform(data.iloc[:,:-1].values, data['144'].values)
    return data


def generate_round(level, accuracy):
    round = []
    for _ in range (level):
        if accuracy == 1:
            round.append(random.randint(1, 9))
        elif accuracy == 2:
            round.append(random.randint(1, 36))
        elif accuracy == 3:
            round.append(random.randint(1, 144))
    return round


def predict(datapoint, accuracy):
    scaled_data = scaler.transform(datapoint.reshape(1, -1))
    pred = models[accuracy - 1].predict(scaled_data)
    touch = np.argwhere(pred > PROB_THRESHOLD)
    #touch = np.argmax(pred)
    if len(touch) > 0:
        return touch[0][1]
    else:
        return 0


def fill_matrix_pos(pos: int, difficulty: int, red: bool):
    mtx = bh.LedMatrix()
    pos -= 1
    if difficulty == 1:
        if pos >= 0 and pos <= 2:
            for row in range (0, 4):
                for col in range (0+(4*pos), 4+(4*pos)):
                    if red: mtx.matrix[col][row].red = 3
                    else: mtx.matrix[col][row].green = 3
        elif pos >= 3 and pos <= 5:
            for row in range (4, 8):
                for col in range (0+(4*(pos-3)), 4+(4*(pos-3))):
                    if red: mtx.matrix[col][row].red = 3
                    else: mtx.matrix[col][row].green = 3
        elif pos >= 6 and pos <= 8:
            for row in range (8, 12):
                for col in range (0+(4*(pos-6)), 4+(4*(pos-6))):
                    if red: mtx.matrix[col][row].red = 3
                    else: mtx.matrix[col][row].green = 3
        return mtx
    elif difficulty == 2:
        if pos >= 0 and pos <= 5:
            for row in range (0, 2):
                for col in range (0+(2*pos), 2+(2*pos)):
                    if red: mtx.matrix[col][row].red = 3
                    else: mtx.matrix[col][row].green = 3
        elif pos >= 6 and pos <= 11:
            for row in range (2, 4):
                for col in range (0+(2*(pos-6)), 2+(2*(pos-6))):
                    if red: mtx.matrix[col][row].red = 3
                    else: mtx.matrix[col][row].green = 3
        elif pos >= 12 and pos <= 17:
            for row in range (4, 6):
                for col in range (0+(2*(pos-12)), 2+(2*(pos-12))):
                    if red: mtx.matrix[col][row].red = 3
                    else: mtx.matrix[col][row].green = 3
        elif pos >= 18 and pos <= 23:
            for row in range (6, 8):
                for col in range (0+(2*(pos-18)), 2+(2*(pos-18))):
                    if red: mtx.matrix[col][row].red = 3
                    else: mtx.matrix[col][row].green = 3
        elif pos >= 24 and pos <= 29:
            for row in range (8, 10):
                for col in range (0+(2*(pos-24)), 2+(2*(pos-24))):
                    if red: mtx.matrix[col][row].red = 3
                    else: mtx.matrix[col][row].green = 3
        elif pos >= 30 and pos <= 35:
            for row in range (10, 12):
                for col in range (0+(2*(pos-30)), 2+(2*(pos-30))):
                    if red: mtx.matrix[col][row].red = 3
                    else: mtx.matrix[col][row].green = 3
        return mtx
    else:
        if red: mtx.matrix[pos%12][int(pos/12)].red = 3
        else: 
            mtx.matrix[pos%12][int(pos/12)].green = 3
        return mtx


def display_win_lose(win):
    result_mtx = bh.LedMatrix()
    if win:
        print("You win!")
        for col in range (0, WIDTH):
            for row in range (0, HEIGHT):
                result_mtx.matrix[col][row].green = 3
    else:
        print("You lose!")
        for col in range (0, WIDTH):
            for row in range (0, HEIGHT):
                result_mtx.matrix[col][row].red = 3
    bh.set_matrix(result_mtx)
    time.sleep(3)
    bh.display_clear()
