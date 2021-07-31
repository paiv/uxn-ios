#include "emu_platform.h"
#include "app_uxn.h"


void
PlatformDelegateAppEntry() {
    uxnapp_init();
}


void
PlatformDelegateAppExit() {
    uxnapp_deinit();
}


void
PlatformDelegateAppRunloop() {
    uxnapp_runloop();
}


void
PlatformDelegateSetDebug(u8 debug) {
    uxnapp_setdebug(debug);
}


void
PlatformDelegateMoveMouse(i16 x, i16 y) {
    uxnapp_movemouse(x, y);
}


void
PlatformDelegateMouseButton(PlatformMouseButton button, u8 down) {
    uxnapp_setmousebutton(button, down);
}


void
PlatformDelegateRenderAudio(u8* buffer, u32 size) {
    uxnapp_audio_callback(buffer, size);
}
