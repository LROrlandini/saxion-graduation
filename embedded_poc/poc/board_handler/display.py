import time
import board_handler


def single_number(lm, number, pos):
    if number == 0:
        for row in range (3, 9):
            if row == 3 or row == 8:
                for i in range (4+pos, 8+pos):
                    lm.matrix[i][row].red = 3
            if row > 3 and row < 9:
                lm.matrix[4+pos][row].red = 3
                lm.matrix[7+pos][row].red = 3

    elif number == 1:
        for row in range (3, 9):
            if row == 3:
                for i in range (5+pos, 7+pos):
                    lm.matrix[i][row].red = 3
            if row > 3 and row < 9:
                lm.matrix[6+pos][row].red = 3

    elif number == 2:
        for row in range (3, 9):
            if row == 3 or row == 5 or row == 8:
                for i in range (4+pos, 8+pos):
                    lm.matrix[i][row].red = 3
            elif row == 4:
                lm.matrix[7+pos][row].red = 3
            else:
                lm.matrix[4+pos][row].red = 3

    elif number == 3:
        for row in range (3, 9):
            if row == 3 or row == 5 or row == 8:
                for i in range (4+pos, 8+pos):
                    lm.matrix[i][row].red = 3
            else:
                lm.matrix[7+pos][row].red = 3

    elif number == 4:
        for row in range (3, 9):
            if row == 5:
                for i in range (4+pos, 8+pos):
                    lm.matrix[i][row].red = 3
            if row > 2 and row < 5:
                lm.matrix[4+pos][row].red = 3
                lm.matrix[7+pos][row].red = 3
            else:
                lm.matrix[7+pos][row].red = 3

    elif number == 5:
        for row in range (3, 9):
            if row == 3 or row == 5 or row == 8:
                for i in range (4+pos, 8+pos):
                    lm.matrix[i][row].red = 3
            elif row == 4:
                lm.matrix[4+pos][row].red = 3
            else:
                lm.matrix[7+pos][row].red = 3

    elif number == 6:
        for row in range (3, 9):
            if row == 3 or row == 5 or row == 8:
                for i in range (4+pos, 8+pos):
                    lm.matrix[i][row].red = 3
            elif row == 4:
                lm.matrix[4+pos][row].red = 3
            else:
                lm.matrix[4+pos][row].red = 3
                lm.matrix[7+pos][row].red = 3

    elif number == 7:
        for row in range (3, 9):
            if row == 3:
                for i in range (4+pos, 8+pos):
                    lm.matrix[i][row].red = 3
            elif row == 4:
                lm.matrix[7+pos][row].red = 3
            elif row == 5:
                lm.matrix[6+pos][row].red = 3
            elif row == 6:
                lm.matrix[5+pos][row].red = 3
            else:
                lm.matrix[4+pos][row].red = 3

    elif number == 8:
        for row in range (3, 9):
            if row == 3 or row == 5 or row == 8:
                for i in range (4+pos, 8+pos):
                    lm.matrix[i][row].red = 3
            if row > 3 and row < 9:
                lm.matrix[4+pos][row].red = 3
                lm.matrix[7+pos][row].red = 3

    else:
        for row in range (3, 9):
            if row == 3 or row == 5 or row == 8:
                for i in range (4+pos, 8+pos):
                    lm.matrix[i][row].red = 3
            if row == 4:
                lm.matrix[4+pos][row].red = 3
                lm.matrix[7+pos][row].red = 3
            else:
                lm.matrix[7+pos][row].red = 3


def display_number(number):
    lm = board_handler.LedMatrix()
    if number < 10:
        single_number(lm, number, 0)
    else:
        dec, num = [int(i) for i in str(number)]
        single_number(lm, dec, -2)
        single_number(lm, num, 2)
    board_handler.set_matrix(lm)
    return lm


def countdown_line(lm, speed):
    for col in range (0, lm.width):
        lm.matrix[col][0].red = 3
    board_handler.set_matrix(lm)
    
    col = 11
    while col > -1:
        lm.matrix[col][0].red = 0
        time.sleep(speed)
        board_handler.set_matrix(lm)
        col -= 1
