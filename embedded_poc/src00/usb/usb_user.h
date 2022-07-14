/*
 * File: usb_user.h
 * Authors: gillebert / orlandini
 *
 * Created on September 30, 2021, 11:27 AM - gillebert
 * Modified on February 20, 2022, 12:00 PM - orlandini
 */

#ifndef USB_USER_H
#define	USB_USER_H

#ifdef	__cplusplus
extern "C" {
#endif

    #include "usb.h"
    #include "usb_device.h"
    #include "usb_device_cdc.h"

    uint8_t read_buffer[CDC_DATA_OUT_EP_SIZE];
    uint8_t rb_r_pntr;
    static uint8_t rb_w_pntr;
    static uint8_t write_buffer[CDC_DATA_IN_EP_SIZE];
    static uint8_t w_pntr;
    
    void usb_loop(void);
    void usb_write_char(uint8_t);
    void usb_write(uint8_t*);
    uint8_t usb_received(void);

#ifdef	__cplusplus
}
#endif

#endif	/* USB_USER_H */

