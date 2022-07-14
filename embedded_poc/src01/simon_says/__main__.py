import signal, os, sys, time
sys.path.insert(1, os.path.abspath('.'))

import board_handler as bh
import helper_module as hf
import gameplay_main, gameplay_sequence, gameplay_manual, gameplay_no_touch


# Clears LED matrix on quit
def signal_handler(signum, frame):
    bh.display_clear()
    exit(1)
signal.signal(signal.SIGINT, signal_handler)


# Displays short boot screen
def bootscreen():
    boot_mtx = bh.LedMatrix()
    boot_mtx.matrix[0][5].red = 3
    boot_mtx.matrix[0][6].red = 3
    boot_mtx.matrix[1][5].red = 3
    boot_mtx.matrix[1][6].red = 3
    boot_mtx.matrix[2][5].red = 3
    boot_mtx.matrix[2][6].red = 3
    boot_mtx.matrix[3][4].red = 3
    boot_mtx.matrix[3][7].red = 3
    boot_mtx.matrix[4][4].red = 3
    boot_mtx.matrix[4][8].red = 3
    boot_mtx.matrix[5][0].red = 3
    boot_mtx.matrix[5][1].red = 3
    boot_mtx.matrix[5][2].red = 3
    boot_mtx.matrix[5][4].red = 3
    boot_mtx.matrix[5][5].red = 3
    boot_mtx.matrix[5][6].red = 3
    boot_mtx.matrix[5][8].red = 3
    boot_mtx.matrix[5][9].red = 3
    boot_mtx.matrix[5][10].red = 3
    boot_mtx.matrix[5][11].red = 3
    boot_mtx.matrix[6][0].red = 3
    boot_mtx.matrix[6][1].red = 3
    boot_mtx.matrix[6][2].red = 3
    boot_mtx.matrix[6][5].red = 3
    boot_mtx.matrix[6][6].red = 3
    boot_mtx.matrix[6][8].red = 3
    boot_mtx.matrix[6][9].red = 3
    boot_mtx.matrix[6][10].red = 3
    boot_mtx.matrix[6][11].red = 3
    
    boot_mtx.matrix[7][2].red = 3
    boot_mtx.matrix[7][8].red = 3
    boot_mtx.matrix[8][3].red = 3
    boot_mtx.matrix[8][7].red = 3
    boot_mtx.matrix[9][4].red = 3
    boot_mtx.matrix[9][5].red = 3
    boot_mtx.matrix[9][6].red = 3
    boot_mtx.matrix[10][4].red = 3
    boot_mtx.matrix[10][5].red = 3
    boot_mtx.matrix[11][4].red = 3
    boot_mtx.matrix[11][5].red = 3

    for _ in range (0, 3):
        bh.set_matrix(boot_mtx)
        time.sleep(0.25)
        bh.display_clear()
        time.sleep(0.25)


# Program main
def main():
    print("Simon Says")
    bootscreen()

    mode = ''
    if len(sys.argv) < 2:
        mode = 'dg'
        print("\nDATA GATHERING")
    else:
        mode = 'ht'
        print("\nHARDWARE TESTING")

    winner = False
    g = 1
    while g > -1 and g < 10:
        if mode == 'dg':
            g = input(
                "\nChoose Gameplay:\n\n"
                "(1) MAIN QUAD        (2) MAIN SQUARE      (3) MAIN LED\n"
                "(4) SEQUENTIAL QUAD  (5) SEQUENTIAL SQUARE(6) SEQUENTIAL LED\n"
                "(7) MANUAL QUAD      (8) MANUAL SQUARE    (9) MANUAL LED\n"
                "(a) NO TOUCH QUAD    (b) NO TOUCH SQUARE  (c) NO TOUCH LED\n"
            )
        else:
            g = input(
                "\nChoose Gameplay:\n\n"
                "(1) MAIN QUAD        (2) MAIN SQUARE      (3) MAIN LED\n"
                "(4) SEQUENTIAL QUAD  (5) SEQUENTIAL SQUARE(6) SEQUENTIAL LED\n"
            )

        if g == '1' or g == '2' or g == '3':
            winner = gameplay_main.main_logic(mode, int(g))
            hf.display_win_lose(winner)
            g = 10

        elif g == '4' or g == '5' or g == '6':
            winner = gameplay_sequence.main_logic(mode, int(g) - 3)
            hf.display_win_lose(winner)
            g = 10

        elif g == '7' or g == '8' or g == '9':
            if mode == 'dg':
                gameplay_manual.main_logic(int(g)- 6)
            else:
                print("Invalid input, try again\n\n")
                g = 0
        
        elif g == 'a' or g == 'b' or g == 'c':
            if mode == 'dg':
                gameplay_no_touch.main_logic(g)
            else:
                print("Invalid input, try again\n\n")
            g = 0

        else:
            print("Invalid input, try again\n\n")
            g = 0


if __name__ == "__main__":
    main()