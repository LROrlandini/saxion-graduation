/* 
 * File:   defines.h
 * Author: gillebert
 *
 * Created on November 1, 2021, 1:01 PM
 */

#ifndef DEFINES_H
#define	DEFINES_H

#ifdef	__cplusplus
extern "C" {
#endif
    
#define _XTAL_FREQ 64000000

#define AN0 0x00
#define AN1 0x01
#define AN2 0x02
#define AN3 0x03
#define AN4 0x04
#define AN5 0x05
#define AN6 0x06
#define AN7 0x07
#define AN8 0x08
#define AN9 0x09
#define AN10 0x0A
#define AN11 0x0B
#define AN12 0x0C
#define AN13 0x0D
#define AN14 0x0E
#define AN15 0x0F
#define AN16 0x10
#define AN17 0x11
#define AN18 0x12
#define AN19 0x13
#define AN20 0x14
#define AN21 0x15
#define AN22 0x16
#define AN23 0x17

struct pin_t{
    volatile unsigned char* port;
    unsigned char pin;
    unsigned char adc_ch;
};

#ifdef	__cplusplus
}
#endif

#endif	/* DEFINES_H */

