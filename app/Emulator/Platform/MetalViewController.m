#import <MetalKit/MetalKit.h>
#import "MetalViewController.h"
#import "Platform.h"
#import "emu_platform.h"


@interface MetalViewController ()

@property (weak, nonatomic) IBOutlet MTKView* canvas;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* canvasScaleButton;
@property (assign, nonatomic) NSUInteger canvasScaleIndex;
@property (strong, nonatomic) NSTimer* navigationBarTimer;

@end


@implementation MetalViewController

- (IBAction)handleScaleButton:(id)sender {
    self.canvasScaleIndex += 1;
}

- (IBAction)handleTapGesture:(id)sender {
    self.navigationBarTimer = nil;
    BOOL hide = !self.navigationController.isNavigationBarHidden;
    [self.navigationController setNavigationBarHidden:hide animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.romAsset.title;
    
    Platform.sharedPlatform.romData = [NSData dataWithContentsOfURL:self.romAsset.assetUrl];

    self.canvas.preferredFramesPerSecond = Platform.sharedPlatform.targetFramesPerSecond;

    CGFloat savedScale = [NSUserDefaults.standardUserDefaults floatForKey:@"AppCanvasScale"];
    int scaleIndex = -1;
    for (NSNumber* scale in self.canvasScales) {
        if (savedScale > 0 && scale.floatValue > savedScale) {
            break;
        }
        ++scaleIndex;
    }
    self.canvasScaleIndex = scaleIndex;

    PlatformDelegateAppEntry();
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (@available(iOS 13.0, *)) {
        self.canvas.device = self.canvas.preferredDevice;
    } else {
        self.canvas.device = MTLCreateSystemDefaultDevice();
    }

    __weak typeof(self) weakSelf = self;
    self.navigationBarTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [weakSelf hideNavigationBar];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.canvas.paused = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    PlatformDelegateAppExit();
}

- (void)setNavigationBarTimer:(NSTimer *)timer {
    [_navigationBarTimer invalidate];
    _navigationBarTimer = timer;
}

- (void)hideNavigationBar {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (NSArray*)canvasScales {
    if (!self.isViewLoaded) {
        return @[@(1.0)];
    }
    CGSize viewSize = self.view.bounds.size;
    UIEdgeInsets safeArea = self.view.safeAreaInsets;
    CGSize canvasSize = Platform.sharedPlatform.canvasSize;
    CGFloat w = MIN((viewSize.width - safeArea.left - safeArea.right) / canvasSize.width, (viewSize.height - safeArea.top - safeArea.bottom) / canvasSize.height);
    NSMutableArray* scales = [NSMutableArray array];
    int r = w;
    for (int i = 1; i <= r; ++i) {
        [scales addObject:@(i)];
    }
    if (w != r) {
        [scales addObject:@(w)];
    }
    return scales;
}

- (void)setCanvasScaleIndex:(NSUInteger)index {
    NSArray* scales = [self canvasScales];
    index %= scales.count;
    _canvasScaleIndex = index;
    CGFloat scale = [scales[index] doubleValue];
    self.canvasScaleButton.title = [NSString stringWithFormat:@"Scale %.2gx", scale];
    [self setCanvasScale:scale];
}

- (void)setCanvasScale:(CGFloat)scale {
    self.canvas.transform = CGAffineTransformMakeScale(scale, scale);
    [NSUserDefaults.standardUserDefaults setFloat:scale forKey:@"AppCanvasScale"];
}

@end
