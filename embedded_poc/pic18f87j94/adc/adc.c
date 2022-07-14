#include "adc.h"

const struct pin_t* current_adc_ch;

void init_adc_auto(){
    ADCON1H = 0b00000100; /* ADC off (7) | 12-bit resolution (2) | Decimal result, right-justified (1-0) */
    ADCON1L = 0b01110000; /* SAMP bit clear after # of TAD (7-4) | Manual sampling (2) | Hold (1) | DONE bit (0) */
    ADCON2H = 0b00000000; /* Datasheet page 437 */
    ADCON2L = 0b00000000; /* Datasheet page 438 */
    ADCON3H = 0b00001111; /* System clock (7) | 15 TAD (4-0) */
    ADCON3L = 0b00001111; /* 16.2/Fosc = TAD (7-0) */
    ADCON5H = 0b00000000; /* Datasheet page 440 */
    ADCON5L = 0b00000000; /* Datasheet page 441 */
}

void init_adc_manual(){
    ADCON1H = 0b00000100; /* ADC off (7) | 12-bit resolution (2) | Decimal result, right-justified (1-0) */
    ADCON1L = 0b00000000; /* SAMP clearing is manual (7-4) | Manual sampling (2) | Hold (1) | DONE bit (0) */
    ADCON2H = 0b00000000; /* Datasheet page 437 */
    ADCON2L = 0b00000000; /* Datasheet page 438 */
    ADCON3H = 0b00001111; /* System clock (7) | 15 TAD (4-0) */
    ADCON3L = 0b00001111; /* 16.2/Fosc = TAD (7-0) */
    ADCON5H = 0b00000000; /* Datasheet page 440 */
    ADCON5L = 0b00000000; /* Datasheet page 441 */
}

void adc_sample_ch(const struct pin_t* io_pin) {
    current_adc_ch = io_pin;
    ADCON1Hbits.ADON = 0; /* ADC off */
    for (unsigned char i = 0; i < 64; i++){
        NOP();
    }
    pin_io(io_pin, 1); /* Input */
    ADCHS0L = io_pin->adc_ch & 0b00011111; /* V-ref (7-5) | Select analog channel specific LED (4-0) */
    for (unsigned char i = 0; i < 64; i++){
        NOP();
    }
    ADCON1Hbits.ADON = 1; /* ADC on */
    for (unsigned char i = 0; i < 64; i++){
        NOP();
    }
    ADCON1Lbits.SAMP = 1; /* Start sampling */
}

void adc_hold() {
    for (unsigned char i = 0; i < 128; i++){
        NOP();
    }
    ADCON1Lbits.SAMP = 0; /* Stop sampling, begin conversion */
}

uint16_t adc_convert() {
    uint16_t adc_value = 0;
    while (!ADCON1Lbits.DONE) {}; /* Checks if conversion is finished */
    adc_value = ADCBUF0; /* Get ADC value from buffer */
    pin_io(current_adc_ch, 0); /* Output */
    return adc_value;
}