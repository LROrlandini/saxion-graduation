/*
 * File: adc.h
 * Authors: gillebert / orlandini
 *
 * Created on September 30, 2021, 11:27 AM - gillebert
 * Modified on February 20, 2022, 12:00 PM - orlandini
 */

#ifndef ADC_H
#define	ADC_H

#include <xc.h>
#include <stdint.h>
#include "../defines.h"
#include "../ledmatrix/ledmatrix.h"

#ifdef	__cplusplus
extern "C" {
#endif

    void init_adc_auto(void);
    void init_adc_manual(void);
    uint16_t measure_adc(const struct pin_t* io_pin);

    void adc_sample_ch(const struct pin_t* io_pin);    
    void adc_hold(void);
    uint16_t adc_convert(void);


#ifdef	__cplusplus
}
#endif

#endif	/* ADC_H */

