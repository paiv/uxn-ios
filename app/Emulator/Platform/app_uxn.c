#include <time.h>
#include "emu_platform.h"
#include "app_uxn.h"

#import "uxn.h"

#include "devices/audio.c"
#if DEBUG
#include "uxn.c"
#else
#include "uxn-fast.c"
#endif

static Uxn _uxn;
//static Ppu _ppu;
//static Apu _apu[POLYPHONY];
static Device *devsystem, *devscreen, *devmouse, *devaudio0;
static Uint8 reqdraw = 0;


static void
redraw(Uxn *u) {
    if(devsystem->dat[0xe]) {
        inspect(&_ppu, u->wst.dat, u->wst.ptr, u->rst.ptr, u->ram.dat);
    }
    PlatformBitmap bg = {
        .width = _ppu.width,
        .height = _ppu.height,
        .pixels = _ppu.bg.pixels,
    };
    PlatformBitmap fg = {
        .width = _ppu.width,
        .height = _ppu.height,
        .pixels = _ppu.fg.pixels,
    };
    PlatformDrawBackground(&bg);
    PlatformDrawForeground(&fg);
    reqdraw = 0;
}


static void
nil_talk(Device *d, Uint8 b0, Uint8 w) {
}


static void
system_talk(Device *d, Uint8 b0, Uint8 w) {
    if(!w) {
        d->dat[0x2] = d->u->wst.ptr;
        d->dat[0x3] = d->u->rst.ptr;
    } else {
        putcolors(&_ppu, &d->dat[0x8]);
        reqdraw = 1;
    }
}


static void
console_talk(Device *d, Uint8 b0, Uint8 w) {
//    if(w && b0 > 0x7)
//        write(b0 - 0x7, (char *)&d->dat[b0], 1);
}


static void
screen_talk(Device *d, Uint8 b0, Uint8 w) {
    if(w && b0 == 0xe) {
        Uint16 x = PEEK16(d->dat, 0x8);
        Uint16 y = PEEK16(d->dat, 0xa);
        Uint8 *addr = &d->mem[mempeek16(d->dat, 0xc)];
        Layer *layer = d->dat[0xe] >> 4 & 0x1 ? &_ppu.fg : &_ppu.bg;
        Uint8 mode = d->dat[0xe] >> 5;
        if(!mode)
            putpixel(&_ppu, layer, x, y, d->dat[0xe] & 0x3);
        else if(mode-- & 0x1)
            puticn(&_ppu, layer, x, y, addr, d->dat[0xe] & 0xf, mode & 0x2, mode & 0x4);
        else
            putchr(&_ppu, layer, x, y, addr, d->dat[0xe] & 0xf, mode & 0x2, mode & 0x4);
        reqdraw = 1;
    }
}


static void
file_talk(Device *d, Uint8 b0, Uint8 w) {
    Uint8 read = b0 == 0xd;
    if(w && (read || b0 == 0xf)) {
        char *name = (char *)&d->mem[mempeek16(d->dat, 0x8)];
        Uint16 result = 0, length = mempeek16(d->dat, 0xa);
        Uint16 offset = mempeek16(d->dat, 0x4);
        Uint16 addr = mempeek16(d->dat, b0 - 1);
        PlatformFile f = PlatformOpenFile(name, read ? "r" : (offset ? "a" : "w"));
        if(f) {
            fprintf(stderr, "%s %s %s #%04x, ", read ? "Loading" : "Saving", name, read ? "to" : "from", addr);
            if(PlatformSeekFile(f, offset, SEEK_SET) != -1)
                result = read ? PlatformReadFile(f, &d->mem[addr], length) : PlatformWriteFile(f, &d->mem[addr], length);
            fprintf(stderr, "%04x bytes\n", result);
            PlatformCloseFile(f);
        }
        mempoke16(d->dat, 0x2, result);
    }
}


static void
audio_talk(Device *d, Uint8 b0, Uint8 w) {
    Apu *c = &_apu[d - devaudio0];
    if(!w) {
        if(b0 == 0x2)
            mempoke16(d->dat, 0x2, c->i);
        else if(b0 == 0x4)
            d->dat[0x4] = apu_get_vu(c);
    } else if(b0 == 0xf) {
//        SDL_LockAudioDevice(audio_id);
        c->len = mempeek16(d->dat, 0xa);
        c->addr = &d->mem[mempeek16(d->dat, 0xc)];
        c->volume[0] = d->dat[0xe] >> 4;
        c->volume[1] = d->dat[0xe] & 0xf;
        c->repeat = !(d->dat[0xf] & 0x80);
        apu_start(c, mempeek16(d->dat, 0x8), d->dat[0xf] & 0x7f);
//        SDL_UnlockAudioDevice(audio_id);
        PlatformAudioOpenOutput();
    }
}


static void
datetime_talk(Device *d, Uint8 b0, Uint8 w) {
    time_t seconds = time(NULL);
    struct tm *t = localtime(&seconds);
    t->tm_year += 1900;
    mempoke16(d->dat, 0x0, t->tm_year);
    d->dat[0x2] = t->tm_mon;
    d->dat[0x3] = t->tm_mday;
    d->dat[0x4] = t->tm_hour;
    d->dat[0x5] = t->tm_min;
    d->dat[0x6] = t->tm_sec;
    d->dat[0x7] = t->tm_wday;
    mempoke16(d->dat, 0x08, t->tm_yday);
    d->dat[0xa] = t->tm_isdst;
}


void
uxnapp_init(void) {
    Uxn* u = &_uxn;

    bootuxn(u);

    // loaduxn
    PlatformCopyRom(u->ram.dat + PAGE_PROGRAM, sizeof(u->ram.dat) - PAGE_PROGRAM);
    
    u16 w, h;
    PlatformGetScreenSize(&w, &h);
    w /= 8;
    h /= 8;
    if (!initppu(&_ppu, w, h)) {
        return;
    }

    devsystem = portuxn(u, 0x0, "system", system_talk);
    portuxn(u, 0x1, "console", console_talk);
    devscreen = portuxn(u, 0x2, "screen", screen_talk);
    devaudio0 = portuxn(u, 0x3, "audio0", audio_talk);
    portuxn(u, 0x4, "audio1", audio_talk);
    portuxn(u, 0x5, "audio2", audio_talk);
    portuxn(u, 0x6, "audio3", audio_talk);
    portuxn(u, 0x7, "---", nil_talk);
    portuxn(u, 0x8, "controller", nil_talk);
    devmouse = portuxn(u, 0x9, "mouse", nil_talk);
    portuxn(u, 0xa, "file", file_talk);
    portuxn(u, 0xb, "datetime", datetime_talk);
    portuxn(u, 0xc, "---", nil_talk);
    portuxn(u, 0xd, "---", nil_talk);
    portuxn(u, 0xe, "---", nil_talk);
    portuxn(u, 0xf, "---", nil_talk);

    mempoke16(devscreen->dat, 2, _ppu.hor * 8);
    mempoke16(devscreen->dat, 4, _ppu.ver * 8);

    evaluxn(u, PAGE_PROGRAM);
    redraw(u);
}


void
uxnapp_deinit(void) {
    PlatformAudioCloseOutput();
    PlatformFree(_ppu.bg.pixels);
    PlatformFree(_ppu.fg.pixels);
}


void
uxnapp_runloop(void) {
    Uxn* u = &_uxn;
    evaluxn(u, mempeek16(devscreen->dat, 0));
    if(reqdraw || devsystem->dat[0xe])
        redraw(u);
}


void
uxnapp_setdebug(u8 debug) {
    Uxn* u = &_uxn;
    devsystem->dat[0xe] = debug ? 1 : 0;
    redraw(u);
}


static int
clamp(int val, int min, int max) {
    return (val >= min) ? (val <= max) ? val : max : min;
}


void
uxnapp_movemouse(i16 mx, i16 my) {
    Uxn* u = &_uxn;

    Uint16 x = clamp(mx, 0, _ppu.hor * 8 - 1);
    Uint16 y = clamp(my, 0, _ppu.ver * 8 - 1);
    mempoke16(devmouse->dat, 0x2, x);
    mempoke16(devmouse->dat, 0x4, y);

    evaluxn(u, mempeek16(devmouse->dat, 0));
}


void
uxnapp_setmousebutton(u8 button, u8 state) {
    Uxn* u = &_uxn;

    Uint8 flag = 0x00;
    switch (button) {
        case 0: flag = 0x01; break;
        case 1: flag = 0x10; break;
    }

    if (state) {
        devmouse->dat[6] |= flag;
    }
    else {
        devmouse->dat[6] &= (~flag);
    }

    evaluxn(u, mempeek16(devmouse->dat, 0));
}


void
uxnapp_audio_callback(Uint8 *stream, Uint32 len) {
    int running = 0;
    Sint16 *samples = (Sint16 *)stream;
    PlatformMemset(stream, 0, len);
    for(int i = 0; i < POLYPHONY; ++i) {
        running += apu_render(&_apu[i], samples, samples + len / 2);
    }
    if (!running) {
        PlatformAudioPauseOutput();
    }
}
