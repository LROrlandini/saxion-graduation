
#include <xc.h>
#include "ledmatrix.h"


void pin_state(const struct pin_t* io_pin, unsigned char state) {
    if (state) {
        *io_pin->port |= 1u << io_pin->pin;
    } else {
        *io_pin->port &= ~(1u << io_pin->pin);
    }
}

void _set_tris(volatile unsigned char* tris, unsigned char pin, unsigned char io) {
    if (io) {
        *tris |= 1u << pin;
    } else {
        *tris &= ~(1u << pin);
    }
}

void pin_io(const struct pin_t* io_pin, unsigned char io) {
    if (io_pin->port == &LATA) {
        _set_tris(&TRISA, io_pin->pin, io);
    } else if (io_pin->port == &LATB) {
        _set_tris(&TRISB, io_pin->pin, io);
    } else if (io_pin->port == &LATC) {
        _set_tris(&TRISC, io_pin->pin, io);
    } else if (io_pin->port == &LATD) {
        _set_tris(&TRISD, io_pin->pin, io);
    } else if (io_pin->port == &LATE) {
        _set_tris(&TRISE, io_pin->pin, io);
    } else if (io_pin->port == &LATF) {
        _set_tris(&TRISF, io_pin->pin, io);
    } else if (io_pin->port == &LATG) {
        _set_tris(&TRISG, io_pin->pin, io);
    } else if (io_pin->port == &LATH) {
        _set_tris(&TRISH, io_pin->pin, io);
    }
}

void reset_matrix() {
    for (unsigned char i = 0; i < 12; i++) {
        for (unsigned char j = 0; j < 12; j++) {
            led_matrix[i][j].red_value = 0;
            led_matrix[i][j].green_value = 0;
        }
    }
}

void bootscreen() {
    for (unsigned char i = 0; i < 12; i++) {
        for (unsigned char j = 0; j < 12; j++) {
            led_matrix[i][j].red_value = (unsigned char)((MAX_INTENSITY * j) << 1) / 12;
            led_matrix[i][j].red_value += 1;
            led_matrix[i][j].red_value >>= 1;
            led_matrix[i][j].green_value = MAX_INTENSITY - led_matrix[i][j].red_value;
        }
    }
}

void matrix_pattern(void) {
    for (unsigned char i = 0; i < 12; i++) {
        size_t j = i + (size_t)rand() / (RAND_MAX / (12 - i) + 1);
        uint8_t t = pattern[j];
        pattern[j] = pattern[i];
        pattern[i] = t;
    }
}