#include "usb_user.h"

void usb_loop() {
    #if defined(USB_POLLING)
        /* Interrupt or polling method.  If using polling, must call
         * this function periodically.  This function will take care
         * of processing and responding to SETUP transactions
         * (such as during the enumeration process when you first
         * plug in).  USB hosts require that USB devices should accept
         * and process SETUP packets in a timely fashion.  Therefore,
         * when using polling, this function should be called
         * regularly (such as once every 1.8ms or faster** [see
         * inline code comments in usb_device.c for explanation when
         * "or faster" applies])  In most cases, the USBDeviceTasks()
         * function does not take very long to execute (ex: <100
         * instruction cycles) before it returns.
         */
        USBDeviceTasks();
    #endif
    /* If the USB device isn't configured yet, we can't really do anything
     * else since we don't have a host to talk to.  So jump back to the
     * top of the while loop.
     */
    if (USBGetDeviceState() < CONFIGURED_STATE) {
        return;
    }

    /* If we are currently suspended, then we need to see if we need to
     * issue a remote wakeup.  In either case, we shouldn't process any
     * keyboard commands since we aren't currently communicating to the host
     * thus just continue back to the start of the while loop.
     */
    if (USBIsDeviceSuspended() == true) {
        return;
    }
    if (USBUSARTIsTxTrfReady() == true) {
        uint8_t i;
        uint8_t num_bytes_read;
        uint8_t tmp_read[CDC_DATA_OUT_EP_SIZE];
        num_bytes_read = getsUSBUSART(tmp_read, sizeof (tmp_read));
        /* For every byte that was read... */
        for (i = 0; i < num_bytes_read; i++) {
            read_buffer[rb_w_pntr] = tmp_read[i];
            rb_w_pntr = (rb_w_pntr + 1) % CDC_DATA_OUT_EP_SIZE;
        }
    }
    if (w_pntr > 0){
        putUSBUSART(write_buffer, w_pntr);
        w_pntr = 0;
    }
    CDCTxService();
}

void usb_write_char(uint8_t character) {
    write_buffer[w_pntr++ % CDC_DATA_IN_EP_SIZE] = character;
}

void usb_write(uint8_t* string) {
    for (char i = 0; i < CDC_DATA_IN_EP_SIZE; i++) {
        if (string[i] == '\0') {
            return; /* Null terminated strings */
        }
        write_buffer[w_pntr++ % CDC_DATA_IN_EP_SIZE] = string[i];
    }
}

uint8_t usb_received() {
    if (rb_w_pntr >= rb_r_pntr) {
        return rb_w_pntr - rb_r_pntr;
    } else {
        return rb_w_pntr + CDC_DATA_OUT_EP_SIZE - rb_r_pntr;
    }
}
