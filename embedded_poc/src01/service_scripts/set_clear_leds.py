import os, sys
sys.path.insert(1, os.path.abspath('.'))

import board_handler as bh

WIDTH = 12
HEIGHT = 12

# Gets user input and switched LEDs on.
def get_indexes():
    print('Enter column and row of LEDs to switch on. \
        Separate values with a space.'
        )
    print('Example:\r0 0 5 6 11 11\n\n')
    indexes = input()
    indexes = indexes.split(' ')
    for i in range (0, len(indexes), 2):
        lm.matrix[int(indexes[i])][int(indexes[i+1])].green = 2
        lm.matrix[int(indexes[i])][int(indexes[i+1])].red = 2
    bh.set_matrix(lm)


lm = bh.LedMatrix(WIDTH, HEIGHT)  # Columns, Rows

if len(sys.argv) < 2:
    bh.clear_matrix(lm)
    print("Enter command line argument 1 to switch on LEDs")
elif sys.argv[1] != '1':
    sys.exit("Enter command line argument 1 to switch on LEDs")
else:
    get_indexes()


