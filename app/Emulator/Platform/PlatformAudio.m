#import <AudioToolbox/AudioToolbox.h>
#import "emu_platform.h"
#import "PlatformAudio.h"


@interface PlatformAudio () {
    AudioQueueRef _audioQueue;
    AudioQueueBufferRef _buffers[4];
}

@end


@implementation PlatformAudio

static BOOL
validOsStatus(OSStatus status, NSString* message) {
    if (status != noErr) {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"%@ %@", message, error);
    }
    return status == noErr;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupAudioQueue];
    }
    return self;
}

- (void)setupAudioQueue {
    const UInt32 bufferSize = 2048;
    AudioStreamBasicDescription format = {
        .mSampleRate = 44100,
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags = (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked),
        .mBytesPerPacket = 2 * sizeof(SInt16),
        .mFramesPerPacket = 1,
        .mBytesPerFrame = 2 * sizeof(SInt16),
        .mChannelsPerFrame = 2,
        .mBitsPerChannel = 8 * sizeof(SInt16),
    };
    dispatch_queue_t dispatchQueue = dispatch_queue_create("uxn_audio", NULL);
    AudioQueueRef audioQueue = nil;
    __weak typeof(self) weakSelf = self;
    OSStatus status = AudioQueueNewOutputWithDispatchQueue(&audioQueue, &format, 0, dispatchQueue, ^(AudioQueueRef _Nonnull inAQ, AudioQueueBufferRef _Nonnull inBuffer) {
        [weakSelf audioQueueCallback:inAQ buffer:inBuffer];
    });
    if (!validOsStatus(status, @"AudioQueueNewOutputWithDispatchQueue")) {
        return;
    }
    _audioQueue = audioQueue;
    
    int bufferCount = sizeof(_buffers) / sizeof(_buffers[0]);
    for (int i = 0; i < bufferCount; ++i) {
        AudioQueueBufferRef buffer = nil;
        OSStatus status = AudioQueueAllocateBuffer(audioQueue, bufferSize, &buffer);
        if (!validOsStatus(status, @"AudioQueueAllocateBuffer")) {
            return;
        }
        _buffers[i] = buffer;

        PlatformMemset(buffer->mAudioData, 0, buffer->mAudioDataBytesCapacity);
        buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;

        status = AudioQueueEnqueueBuffer(audioQueue, buffer, 0, nil);
        if (!validOsStatus(status, @"AudioQueueEnqueueBuffer")) {
            return;
        }
    }
}

- (void)setIsEnabled:(BOOL)isEnabled {
    if (_isEnabled == isEnabled) {
        return;
    }
    _isEnabled = isEnabled;
    
    if (isEnabled) {
        OSStatus status = AudioQueueStart(_audioQueue, NULL);
        if (!validOsStatus(status, @"AudioQueueStart")) {
            return;
        }
    }
    else {
        OSStatus status = AudioQueueDispose(_audioQueue, false);
        if (!validOsStatus(status, @"AudioQueueDispose")) {
            return;
        }
    }
}

- (void)audioQueueCallback:(AudioQueueRef)inAQ buffer:(AudioQueueBufferRef)inBuffer {
    if (!self.isEnabled) {
        return;
    }
    BOOL renderSilence = YES;
    
    if (self.isEnabled) {
        PlatformDelegateRenderAudio(inBuffer->mAudioData, inBuffer->mAudioDataBytesCapacity);
        inBuffer->mAudioDataByteSize = inBuffer->mAudioDataBytesCapacity;
        renderSilence = NO;
    }
    
    if (renderSilence) {
        PlatformMemset(inBuffer->mAudioData, 0, inBuffer->mAudioDataBytesCapacity);
        inBuffer->mAudioDataByteSize = inBuffer->mAudioDataBytesCapacity;
    }
    
    OSStatus status = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil);
    if (!validOsStatus(status, @"AudioQueueEnqueueBuffer")) {
        return;
    }
}

@end
