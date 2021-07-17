#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif


typedef uint8_t u8;
typedef int16_t i16;
typedef uint16_t u16;
typedef int32_t i32;
typedef uint32_t u32;
typedef float r32;


typedef struct {
    u16 width;
    u16 height;
    u32* pixels;
} PlatformBitmap;


typedef enum {
    PlatformMouseLeftButton,
    PlatformMouseRightButton,
} PlatformMouseButton;


typedef void* PlatformFile;


void* PlatformAlloc(u32 size);
void PlatformFree(void* memory);
void PlatformMemset(void* memory, u8 value, u32 size);

void PlatformGetScreenSize(u16* width, u16* height);
void PlatformDrawBackground(const PlatformBitmap* bitmap);
void PlatformDrawForeground(const PlatformBitmap* bitmap);

void PlatformCopyRom(u8* buffer, u32 size);
void PlatformAudioOpenOutput(void);
void PlatformAudioPauseOutput(void);
void PlatformAudioCloseOutput(void);

PlatformFile PlatformOpenFile(const char* name, const char* mode);
void PlatformCloseFile(PlatformFile file);
u32 PlatformReadFile(PlatformFile file, u8* ptr, u32 size);
u32 PlatformWriteFile(PlatformFile file, const u8* ptr, u32 size);
i32 PlatformSeekFile(PlatformFile file, u32 offset, u32 whence);

void PlatformDelegateAppEntry(void);
void PlatformDelegateAppRunloop(void);
void PlatformDelegateAppExit(void);
void PlatformDelegateMoveMouse(i16 x, i16 y);
void PlatformDelegateMouseButton(PlatformMouseButton button, u8 down);
void PlatformDelegateRenderAudio(u8* buffer, u32 size);


#ifdef __cplusplus
}
#endif
