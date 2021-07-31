#pragma once

#ifdef __cplusplus
extern "C" {
#endif


void
uxnapp_init(void);


void
uxnapp_deinit(void);


void
uxnapp_runloop(void);


void
uxnapp_setdebug(u8 debug);


void
uxnapp_movemouse(i16 x, i16 y);


void
uxnapp_setmousebutton(u8 button, u8 state);


void
uxnapp_audio_callback(u8* stream, u32 len);


#ifdef __cplusplus
}
#endif
