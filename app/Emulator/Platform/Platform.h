#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface Platform : NSObject

+ (instancetype)sharedPlatform;

- (void)renderLoop:(void (^) (void))block;

@property (assign, nonatomic, readonly) CGSize canvasSize;
@property (strong, nonatomic, nullable, readonly) NSData* bgPixels;
@property (strong, nonatomic, nullable, readonly) NSData* fgPixels;
@property (assign, nonatomic, readonly) NSInteger targetFramesPerSecond;
@property (strong, nonatomic, nullable) NSData* romData;
@property (assign, nonatomic) BOOL isAudioEnabled;

- (void)setMousePosition:(CGPoint)point;
- (void)handleMouseButton:(NSUInteger)button isDown:(BOOL)down;
- (void)setBackgroundPixels:(void*)pixels;
- (void)setForegroundPixels:(void*)pixels;

@end


NS_ASSUME_NONNULL_END
