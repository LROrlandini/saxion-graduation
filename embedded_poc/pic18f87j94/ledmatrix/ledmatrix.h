/* Microchip Technology Inc. and its subsidiaries.  You may use this software 
 * and any derivatives exclusively with Microchip products. 
 * 
 * THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS".  NO WARRANTIES, WHETHER 
 * EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED 
 * WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A 
 * PARTICULAR PURPOSE, OR ITS INTERACTION WITH MICROCHIP PRODUCTS, COMBINATION 
 * WITH ANY OTHER PRODUCTS, OR USE IN ANY APPLICATION. 
 *
 * IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
 * INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND 
 * WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS 
 * BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE.  TO THE 
 * FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS 
 * IN ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF 
 * ANY, THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
 *
 * MICROCHIP PROVIDES THIS SOFTWARE CONDITIONALLY UPON YOUR ACCEPTANCE OF THESE 
 * TERMS. 
 */

/* 
 * File:   
 * Author: 
 * Comments:
 * Revision history: 
 */

// This is a guard condition so that contents of this file are not included
// more than once.  
#ifndef LEDMATRIX_H
#define	LEDMATRIX_H

#include <xc.h> // include processor files - each processor file is guarded. 
#include <stdint.h>
#include <stdlib.h>
#include "../defines.h"

#define MAX_INTENSITY 4
#define NUM_ROWS 12
#define NUM_COLS 12

typedef union pixel_t {
    unsigned char bytes[1];
    struct {
        unsigned red_value : 4;
        unsigned green_value : 4;
    };
} pixel;

struct row_t {
    const struct pin_t* red;
    const struct pin_t* green;
};

const struct pin_t _D0 = {&LATD, 0, 0xFF};
const struct pin_t _D1 = {&LATD, 1, 0xFF};
const struct pin_t _D2 = {&LATD, 2, 0xFF};
const struct pin_t _D3 = {&LATD, 3, 0xFF};
const struct pin_t _D4 = {&LATD, 4, 0xFF};
const struct pin_t _D5 = {&LATD, 5, 0xFF};
const struct pin_t _D6 = {&LATD, 6, 0xFF};
const struct pin_t _D7 = {&LATD, 7, 0xFF};
const struct pin_t _E0 = {&LATE, 0, 0xFF};
const struct pin_t _E1 = {&LATE, 1, 0xFF};
const struct pin_t _E2 = {&LATE, 2, 0xFF};
const struct pin_t _E3 = {&LATE, 3, 0xFF};

const struct pin_t* columns[12] ={
    &_D0, &_D1, &_D2, &_D3, &_D4, &_D5,
    &_D6, &_D7, &_E0, &_E1, &_E2, &_E3
};

const struct pin_t _H5 = {&LATH, 5, AN13};
const struct pin_t _A3 = {&LATA, 3, AN3};
const struct pin_t _A1 = {&LATA, 1, AN1};
const struct pin_t _A5 = {&LATA, 5, AN4};
const struct pin_t _C2 = {&LATC, 2, AN9};
const struct pin_t _H1 = {&LATH, 1, AN22};
const struct pin_t _H3 = {&LATH, 3, AN20};
const struct pin_t _G1 = {&LATG, 1, AN19};
const struct pin_t _G3 = {&LATG, 3, AN17};
const struct pin_t _F7 = {&LATF, 7, AN5};
const struct pin_t _F5 = {&LATF, 5, AN10};
const struct pin_t _H7 = {&LATH, 7, AN15};

const struct pin_t _H4 = {&LATH, 4, AN12};
const struct pin_t _A2 = {&LATA, 2, AN2};
const struct pin_t _A0 = {&LATA, 0, AN0};
const struct pin_t _A4 = {&LATA, 4, AN6};
const struct pin_t _H0 = {&LATH, 0, AN23};
const struct pin_t _H2 = {&LATH, 2, AN21};
const struct pin_t _G0 = {&LATG, 0, AN8};
const struct pin_t _G2 = {&LATG, 2, AN18};
const struct pin_t _G4 = {&LATG, 4, AN16};
const struct pin_t _F6 = {&LATF, 6, AN11};
const struct pin_t _F2 = {&LATF, 2, AN7};
const struct pin_t _H6 = {&LATH, 6, AN14};

const struct row_t rows[12] = {
    {&_H5, &_H4}, {&_A3, &_A2}, {&_A1, &_A0}, {&_A5, &_A4},
    {&_C2, &_H0}, {&_H1, &_H2}, {&_H3, &_G0}, {&_G1, &_G2},
    {&_G3, &_G4}, {&_F7, &_F6}, {&_F5, &_F2}, {&_H7, &_H6}
};

const struct pin_t _BUZZER = {&LATE, 4, 0xFF};
unsigned char matrix_updated;
unsigned char current_meas_array;
uint8_t toggle_adc = 0;
uint8_t pattern[] = {0, 2, 4, 6, 8, 10, 11, 9, 7, 5, 3, 1};
//uint8_t pattern[] = {0, 11, 1, 10, 2, 9, 3, 8, 4, 7, 5, 6};
//uint8_t pattern[] = {5, 6, 4, 7, 3, 8, 2, 9, 1, 10, 0, 11};
uint16_t measurements[2][NUM_COLS][NUM_ROWS];
pixel led_matrix[NUM_COLS][NUM_ROWS];

void reset_matrix(void);
void bootscreen(void);
void pin_state(const struct pin_t* io_pin, unsigned char state);
void pin_io(const struct pin_t* io_pin, unsigned char io);
void change_pattern(void);

#ifdef	__cplusplus
extern "C" {
#endif /* __cplusplus */

#ifdef	__cplusplus
}
#endif /* __cplusplus */

#endif	/* XC_HEADER_TEMPLATE_H */

