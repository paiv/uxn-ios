#import "Platform.h"
#import "PlatformAudio.h"
#import "emu_platform.h"


void*
PlatformAlloc(u32 size) {
    return calloc(size, 1);
}


void
PlatformFree(void* memory) {
    free(memory);
}


void
PlatformMemset(void* memory, u8 value, u32 size) {
    memset(memory, value, size);
}


void
PlatformGetScreenSize(u16* width, u16* height) {
    CGSize size = [Platform.sharedPlatform canvasSize];
    *width = size.width;
    *height = size.height;
}


void
PlatformDrawBackground(const PlatformBitmap* bitmap) {
    [Platform.sharedPlatform setBackgroundPixels:bitmap->pixels];
}


void
PlatformDrawForeground(const PlatformBitmap* bitmap) {
    [Platform.sharedPlatform setForegroundPixels:bitmap->pixels];
}


void
PlatformCopyRom(u8* buffer, u32 size) {
    NSData* data = Platform.sharedPlatform.romData;
    if (data && data.length <= size) {
        memcpy(buffer, data.bytes, data.length);
    }
}


void
PlatformAudioOpenOutput(void) {
    Platform.sharedPlatform.isAudioEnabled = YES;
}


void
PlatformAudioPauseOutput(void) {
    
}


void
PlatformAudioCloseOutput(void) {
    Platform.sharedPlatform.isAudioEnabled = NO;
}


PlatformFile
PlatformOpenFile(const char* name, const char* mode) {
    NSURL* docs = [NSFileManager.defaultManager URLForDirectory:(NSDocumentDirectory) inDomain:(NSUserDomainMask) appropriateForURL:nil create:YES error:nil];
    if (!docs) { return nil; }
    NSURL* vfs = [docs URLByAppendingPathComponent:@"vfs" isDirectory:YES];
    NSURL* fn = [vfs URLByAppendingPathComponent:[NSString stringWithCString:name encoding:NSUTF8StringEncoding]];
    return fopen(fn.path.UTF8String, mode);
}


void
PlatformCloseFile(PlatformFile file) {
    fclose((FILE*)file);
}


u32
PlatformReadFile(PlatformFile file, u8* ptr, u32 size) {
    return (u32)fread(ptr, 1, size, (FILE*)file);
}


u32
PlatformWriteFile(PlatformFile file, const u8* ptr, u32 size) {
    return (u32)fwrite(ptr, 1, size, (FILE*)file);
}


i32
PlatformSeekFile(PlatformFile file, u32 offset, u32 whence) {
    return fseek((FILE*)file, offset, whence);
}


@interface Platform ()

@property (assign, nonatomic) CGSize canvasSize;
@property (strong, nonatomic, nullable) NSData* bgPixels;
@property (strong, nonatomic, nullable) NSData* fgPixels;
@property (assign, nonatomic) NSInteger targetFramesPerSecond;
@property (assign, nonatomic) CGContextRef imageContext;
@property (strong, nonatomic, nullable) UIImage* backgroundImage;
@property (strong, nonatomic, nullable) UIImage* foregroundImage;
@property (strong, nonatomic) PlatformAudio* audio;

@end


@implementation Platform


+ (instancetype)sharedPlatform {
    static dispatch_once_t onceToken;
    static Platform* instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[Platform alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.canvasSize = CGSizeMake(512, 320);
        self.audio = [[PlatformAudio alloc] init];
        self.targetFramesPerSecond = 60;
#if TARGET_OS_SIMULATOR
        self.targetFramesPerSecond = 30;
#endif
    }
    return self;
}

- (void)dealloc {
    self.imageContext = nil;
}

- (void)setCanvasSize:(CGSize)canvasSize {
    _canvasSize = canvasSize;
    
    size_t components = 4;
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = canvasSize.width * components;
    uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(NULL, canvasSize.width, canvasSize.height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
    
    CGColorSpaceRelease(colorSpace);
    
    self.imageContext = context;
}

- (void)setImageContext:(CGContextRef)imageContext {
    CGContextRelease(_imageContext);
    _imageContext = imageContext;
}

- (void)renderLoop:(void (^) (void))block {
    UIGraphicsPushContext(self.imageContext);
    block();
    UIGraphicsPopContext();
}

- (void)setMousePosition:(CGPoint)point {
    PlatformDelegateMoveMouse(point.x, point.y);
}

- (void)handleMouseButton:(NSUInteger)button isDown:(BOOL)down {
    PlatformDelegateMouseButton((PlatformMouseButton)button, down);
}

- (void)setIsAudioEnabled:(BOOL)isAudioEnabled {
    _isAudioEnabled = isAudioEnabled;
    if (isAudioEnabled) {
        if (!self.audio) {
            self.audio = [[PlatformAudio alloc] init];
        }
        self.audio.isEnabled = YES;
    }
    else {
        if (self.audio) {
            self.audio.isEnabled = NO;
            self.audio = nil;
        }
    }
}

- (void)setBackgroundPixels:(void *)pixels {
    CGSize canvasSize = self.canvasSize;
    NSUInteger count = 4 * canvasSize.width * canvasSize.height;
    self.bgPixels = [NSData dataWithBytes:pixels length:count];
}

- (void)setForegroundPixels:(void *)pixels {
    CGSize canvasSize = self.canvasSize;
    NSUInteger count = 4 * canvasSize.width * canvasSize.height;
    self.fgPixels = [NSData dataWithBytes:pixels length:count];
}

@end
