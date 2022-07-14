/*******************************************************************************
Copyright 2016 Microchip Technology Inc. (www.microchip.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

To request to license the code under the MLA license (www.microchip.com/mla_license), 
please contact mla_licensing@microchip.com
*******************************************************************************/

#include "system.h"
#include "../ledmatrix/ledmatrix.h"
#include "../usb/usb.h"
#include "../usb/usb_user.h"
#include "../adc/adc.h"

/** CONFIGURATION Bits **********************************************/
#pragma config STVREN = ON      // Stack Overflow/Underflow Reset (Enabled)
#pragma config XINST = OFF      // Extended Instruction Set (Disabled)
#pragma config BOREN = ON       // Brown-Out Reset Enable (Controlled with SBOREN bit, disabled in Deep Sleep)
#pragma config BORV = 0         // Brown-out Reset Voltage (2.0V)
#pragma config CP0 = OFF        // Code Protect (Program memory is not code-protected)
#pragma config FOSC = FRCPLL    // Oscillator (Fast RC Oscillator with PLL module (FRCPLL))
#pragma config SOSCSEL = LOW    // T1OSC/SOSC Power Selection Bits (Low Power T1OSC/SOSC circuit selected)
#pragma config CLKOEN = OFF     // Clock Out Enable Bit (CLKO output disabled on the RA6 pin)
#pragma config IESO = OFF       // Internal External Oscillator Switch Over Mode (Disabled)
#pragma config PLLDIV = NODIV   // PLL Frequency Multiplier Select bits (96 MHz PLL selected; No divide - Oscillator used directly (4 MHz input))
#pragma config POSCMD = NONE    // Primary Oscillator Select (Primary oscillator disabled)
#pragma config FSCM = CSECMD    // Clock Switching and Monitor Selection Configuration bits (Clock switching is enabled, fail safe clock monitor is disabled)
#pragma config WPFP = WPFP255   // Write/Erase Protect Page Start/End Boundary (Write Protect Program Flash Page 255)
#pragma config WPDIS = WPDIS    // Segment Write Protection Disable (Disabled)
#pragma config WPEND = WPENDMEM // Segment Write Protection End Page Select (Write Protect from WPFP to the last page of memory)
#pragma config WPCFG = WPCFGDIS // Write Protect Configuration Page Select (Disabled)
#pragma config T5GSEL = T5G     // TMR5 Gate Select bit (TMR5 Gate is driven by the T5G input)
#pragma config CINASEL = DEFAULT// CxINA Gate Select bit (C1INA and C3INA are on their default pin locations)
#pragma config EASHFT = ON      // External Address Shift bit (Address Shifting enabled)
#pragma config ABW = MM         // Address Bus Width Select bits (8-bit address bus)
#pragma config BW = 16          // Data Bus Width (16-bit external bus mode)
#pragma config WAIT = OFF       // External Bus Wait (Disabled)
#pragma config IOL1WAY = OFF    // IOLOCK One-Way Set Enable bit (the IOLOCK bit can be set and cleared using the unlock sequence)
#pragma config LS48MHZ = SYSX2  // USB Low Speed Clock Select bit (Divide-by-2 (System clock must be 12 MHz))
#pragma config MSSPMSK2 = MSK7  // MSSP2 7-Bit Address Masking Mode Enable bit (7 Bit address masking mode)
#pragma config MSSPMSK1 = MSK7  // MSSP1 7-Bit Address Masking Mode Enable bit (7 Bit address masking mode)
#pragma config WDTWIN = PS25_0  // Watch Dog Timer Window (Watch Dog Timer Window Width is 25 percent)
#pragma config WDTCLK = LPRC    // Watch Dog Timer Clock Source (Always use INTOSC/LPRC)
#pragma config WDTPS = 32768    // Watchdog Timer Postscale (1:32768)
#pragma config WDTEN = ON       // Watchdog Timer Disabled; SWDTEN can control WDT
#pragma config WINDIS = WDTSTD  // Windowed Watchdog Timer Disable (Standard WDT selected; windowed WDT disabled)
#pragma config WPSA = 128       // WDT Prescaler (WDT prescaler ratio of 1:128)
#pragma config RETEN = OFF      // Retention Voltage Regulator Control Enable (Retention not available)
#pragma config VBTBOR = OFF     // VBAT BOR Enable (VBAT BOR is disabled)
#pragma config DSBOREN = ON     // Deep Sleep BOR Enable (BOR enabled in Deep Sleep)
#pragma config DSBITEN = ON     // DSEN Bit Enable bit (Deep Sleep is controlled by the register bit DSEN)
#pragma config DSWDTPS = DSWDTPS1F// Deep Sleep Watchdog Timer Postscale Select (1:68719476736 (25.7 Days))
#pragma config DSWDTEN = ON     // Deep Sleep Watchdog Timer Enable (DSWDT Enabled)
#pragma config DSWDTOSC = LPRC  // DSWDT Reference Clock Select (DSWDT uses LPRC as reference clock)

 
/*********************************************************************
* Function: void SYSTEM_Initialize( SYSTEM_STATE state )
*
* Overview: Initializes the system.
*
* PreCondition: None
*
* Input:  SYSTEM_STATE - the state to initialize the system into
*
* Output: None
*
********************************************************************/
void SYSTEM_Initialize( SYSTEM_STATE state )
{
    switch (state)
    {
        case SYSTEM_STATE_USB_START:
            #if(USB_SPEED_OPTION == USB_FULL_SPEED)
                /* Enable INTOSC active clock tuning if full speed */
                ACTCON = 0x90; /* Enable active clock self tuning for USB operation */
                while (OSCCON2bits.LOCK == 0);
            #endif
            break;
        case SYSTEM_STATE_USB_SUSPEND:
            break;
        case SYSTEM_STATE_USB_RESUME:
            break;
    }
}

unsigned char active_col = 0;
unsigned char previous_col = 11;
unsigned char row_input = 0;
unsigned char reading = 0;
unsigned char read_px = 255;
unsigned char intensity_cnt = 0;
bool buzz = 0;
int8_t slow_motion = 0;
uint16_t refresh_counter = 0;

void set_channel(unsigned char row) {
    pin_io(rows[row].green, 0); /* Output */
    pin_state(rows[row].green,1); /* Switch LED on */
    pin_io(rows[row].red, 0); /* Output */
    pin_state(rows[row].red,0); /* Switch LED off */

    for (unsigned char i = 0; i < 64; i++){
        NOP();
    }
    adc_sample_ch(rows[row].red);

}

void read_pixel(unsigned char row, unsigned char col) {
    if (reading == MAX_INTENSITY - 1) {
        set_channel(row);
    } else if (reading == 2) {
        adc_hold();
    } else if (reading == 1) {
        measurements[current_meas_array][col][row] = adc_convert();
    }
    reading--;
}

void turn_px_off(unsigned char row) {
    pin_state(rows[row].red, 0);
    pin_state(rows[row].green, 0);
}

void write_pixel(unsigned char row, unsigned char col) {
    if (led_matrix[col][row].red_value > intensity_cnt) {
        pin_state(rows[row].red, 1);
    } else {
        pin_state(rows[row].red, 0);
    }
    if (led_matrix[col][row].green_value > intensity_cnt) {
        pin_state(rows[row].green, 1);
    } else {
        pin_state(rows[row].green, 0);
    }
}

void led_matrix_io(void){
    slow_motion++;
    if(slow_motion > 0) {
        slow_motion = 0; /* Make value negative to slow time */

        if(previous_col != active_col) {
            pin_state(columns[previous_col], 0);
        }

        for (unsigned char row_output = 0; row_output < 12; row_output++) {
            if ((row_output == pattern[row_input]) && toggle_adc) {
                if (reading) {
                    read_pixel(row_output, active_col);
                }
            } else if (((row_output == (pattern[row_input]+1)) || (pattern[row_input] == 11 && row_output==0)) && toggle_adc) {
                turn_px_off(row_output);
            } else {
                write_pixel(row_output, active_col); 
            }
        }

        if (previous_col != active_col) {
            pin_state(columns[active_col], 1);
            previous_col = active_col;
        }

        intensity_cnt++;
        if (intensity_cnt > MAX_INTENSITY) {
            intensity_cnt = 0;
            active_col++;
            reading = MAX_INTENSITY;
            if (active_col > 11) {
                active_col = 0;
                row_input++;
                if (row_input > 11) {
                    row_input=0;
                    current_meas_array++;
                    current_meas_array = current_meas_array % 2;
                    matrix_updated = true;
                    //change_pattern();
                }
            }
        }
    }
}    

void toggle_buzzer(void) {
    buzz = !buzz;
    pin_state(&_BUZZER, buzz);
}

#if(__XC8_VERSION < 2000)
    #define INTERRUPT interrupt
#else
    #define INTERRUPT __interrupt()
#endif

/*
 * Interrupt function called when a system interrupt happens.
 * Interrupts are currently being triggered by the timer, when
 * the timer register matches the PR2 value and by the USB device.
 */
void INTERRUPT SYS_InterruptHigh(void)
{
    if (TMR2IF) {
        TMR2IF = 0;
        toggle_buzzer();
        led_matrix_io();
    }
    #if defined(USB_INTERRUPT)
        USBDeviceTasks();
    #endif
}
