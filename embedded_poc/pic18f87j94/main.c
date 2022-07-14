/*
 * File: main.c
 * Authors: gillebert / orlandini
 *
 * Created on September 30, 2021, 11:27 AM - gillebert
 * Modified on February 20, 2022, 12:00 PM - orlandini
 */

#include "system/system.h"
#include "usb/usb_user.h"
#include "adc/adc.h"
#include <stdio.h>
#include "system/git.h"
#include "ledmatrix/ledmatrix.h"
#include "defines.h"
#include <xc.h>
#include <string.h>

#define _XTAL_FREQ 64000000
#define NULL_TERM (uint8_t)'\0'

unsigned char print_row = 0;
unsigned char print_col = 0;
unsigned char writing = 0;
unsigned char read_from_usb = false;
unsigned char usb_col = 0;
unsigned char buttons_changed = 0;
uint8_t toggle_buz = 1;

typedef union button_value {
    uint8_t data;
    struct {
        unsigned state : 1;
        unsigned debounce : 7;
    };
} button_value_t;

typedef struct button {
    const struct pin_t pin;
    button_value_t state;
} button_t;

button_t buttons[6] = {{{&PORTB, 0}, 0x00},
                       {{&PORTB, 1}, 0x00},
                       {{&PORTB, 2}, 0x00},
                       {{&PORTB, 3}, 0x00},
                       {{&PORTB, 4}, 0x00},
                       {{&PORTB, 5}, 0x00}};
;

void init_tmr2(void) {
    T2CON = 0b00001010; /* 1:2 Postscale (3) | Timer 2 OFF (2) | Prescaler 16 (1-0) */
    PR2 = 200; /* Period register; Value indicates interval in uS (200 = 400uS, 250 = 500uS) */
    PIE1bits.TMR2IE = 1; /* Enables timer 2 interrupt when match with PR2 */
    T2CONbits.TMR2ON = 1; /* Starts timer 2 */
}

void char_to_string(uint16_t character, uint8_t* str_out) {
    unsigned char length = 0;
    if(character > 999) {
        length = 4;
    } else if(character > 99) {
        length = 3;
    } else if (character > 9) {
        length = 2;
    } else {
        length = 1;
    }
    for (unsigned char i = length; i > 0; i--) {
        str_out[i-1] = 48 + character % 10;
        character /= 10;
    }
}

void print_values(void) {
    if (toggle_adc) {
        if (print_col == 0 && print_row == 0) {
            usb_write((uint8_t*)"LM=[\0");
            usb_write_char((uint8_t)'[');
        }
        uint8_t string[5] = "\0\0\0\0\0";
        char_to_string(measurements[(current_meas_array + 1) % 2][print_col][print_row], string);
        usb_write(string);

        if (print_col<11) {
            usb_write_char((uint8_t)',');
        }
        print_col++;
        if (print_col > 11) {
            print_col = 0;
            if (print_row < 11) {
                usb_write((uint8_t*)"], [\0"); 
            }
            print_row++;
            if(print_row > 11) {
                print_row=0;
                writing = 0;
                usb_write_char((uint8_t)']');
                usb_write_char((uint8_t)']');
                usb_write_char((uint8_t)'\n');
            }
        }
    }
}

void print_buttons(void) {
    usb_write((uint8_t*)"BM=[\0");
    for (unsigned char i = 0; i < 6; i++) {
        if (buttons[i].state.state == 1) {
            usb_write_char((uint8_t)'1');
        } else {
            usb_write_char((uint8_t)'0');
        }
        buttons[i].state.debounce = 0;   
        if (i != 5) {
            usb_write_char((uint8_t)',');
            usb_write_char((uint8_t)' ');
        }
    }
    usb_write_char((uint8_t)']');
    usb_write_char((uint8_t)'\n');
}

void check_buttons(void) {
    for (unsigned char i = 0; i < 6; i++) {
        unsigned char val = ((*buttons[i].pin.port) >> buttons[i].pin.pin) & 0b00000001;
        if (buttons[i].state.state == val) {
            buttons[i].state.debounce++;
            if (buttons[i].state.debounce > 32) {
                buttons[i].state.debounce = 0;
                if (val) {
                    buttons[i].state.state = 0;
                } else {
                    buttons[i].state.state = 1;
                }
                buttons_changed = true;
            }
        } else {
            buttons[i].state.debounce = 0;
        }
    }
}

void main(void) {
    SYSTEM_Initialize(SYSTEM_STATE_USB_START);
    INTCONbits.GIEH = 1; /* Enables unmasked interrupts */
    INTCONbits.GIEL = 1; /* Enables unmasked peripheral interrupts */

    USBDeviceInit();
    USBDeviceAttach();

    /* 
     * Pin direction: 0 for output, 1 for input.
     * All LEDs set as output pins.
     */
    TRISA = 0xc0;
    TRISB = 0xff;
    TRISC = 0x04;
    TRISD = 0x00;
    //TRISE = 0xE0; /* 0xE0 to enable buzzer wire | 0xF0 to disable it */
    TRISE = 0xF0; /* 0xE0 to enable buzzer wire | 0xF0 to disable it */
    TRISF = 0x03;
    TRISG = 0xe0;
    TRISH = 0x00;

    init_adc_manual();
    init_tmr2();
    //change_pattern();

    for (unsigned char row = 0; row < 12; row++) {
        pin_state(rows[row].red, 0);
        pin_state(rows[row].green, 0);
    }
    bootscreen();
        for (unsigned char i = 0; i < 2; i++) {
            ClrWdt();
            __delay_ms(250);
        }
    reset_matrix();
        
    while (true) {
        SYSTEM_Tasks();
        ClrWdt();
        
        if (matrix_updated) {
            writing = true; /* TODO write array */
        }
        if (!buttons_changed) {
            check_buttons();
        }
        if (!buttons_changed && writing && cdc_trf_state == CDC_TX_READY) {
            matrix_updated = false;
            print_values();
        }
        if (buttons_changed && cdc_trf_state == CDC_TX_READY) {
            buttons_changed = false;
            print_buttons();
        }

        CDCTxService();
        uint8_t tmp_msg[32];
        unsigned char full_msg = false;
        for (char i = 0; i < usb_received(); i++) {
            if (!read_from_usb) {
                switch (read_buffer[(rb_r_pntr + i) % CDC_DATA_OUT_EP_SIZE]) {
                    case 0x0D: /* "\r" */
                        tmp_msg[i] = NULL_TERM; /* Make 0 terminated string */
                        full_msg = true;
                        unsigned char max = usb_received();
                        rb_r_pntr = (rb_r_pntr + i + 1) % CDC_DATA_OUT_EP_SIZE;
                        i = max;
                        break;
                    default:
                        tmp_msg[i] = read_buffer[(rb_r_pntr + i) % CDC_DATA_OUT_EP_SIZE];
                        break;
                }
            } else {
                tmp_msg[i] = read_buffer[(rb_r_pntr + i) % CDC_DATA_OUT_EP_SIZE];
                if (i == NUM_ROWS-1) {
                    full_msg = true;
                    unsigned char max = usb_received();
                    rb_r_pntr = (rb_r_pntr + i+1) % CDC_DATA_OUT_EP_SIZE;
                    i = max;
                }
            }
        }

        if (full_msg) {
            full_msg = false;
            if (!read_from_usb) {
                if (strcmp((const char*)tmp_msg, "Get\0") == 0) {
                   writing = true;
                } else if (strcmp((const char*)tmp_msg, "Set\0") == 0) {
                   read_from_usb = 1;
                } else if (strcmp((const char*)tmp_msg, "Buz\0") == 0) {
                    toggle_buz = !toggle_buz;
                    pin_io(&_BUZZER, toggle_buz);
                } else if (strcmp((const char*)tmp_msg, "Adc\0") == 0) {
                    toggle_adc = !toggle_adc;
                }
            } else {
                read_from_usb = 1;
                for (unsigned char row = 0; row < NUM_ROWS; row++) {
                    led_matrix[usb_col][row].bytes[0] = tmp_msg[row];
                }
                usb_col++;
                if (usb_col >= NUM_COLS) {
                    usb_col = 0;
                    read_from_usb = false;
                }
            }
        }
        usb_loop(); /* Checks if something was received or needs to be sent */
    }
    return;
}
