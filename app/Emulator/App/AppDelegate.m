#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    [self setupVfs];
    [self setupAudio];
    return YES;
}

- (void)setupVfs {
    NSURL* docs = [NSFileManager.defaultManager URLForDirectory:(NSDocumentDirectory) inDomain:(NSUserDomainMask) appropriateForURL:nil create:YES error:nil];
    if (!docs) { return; }
    NSURL* vfs = [docs URLByAppendingPathComponent:@"vfs" isDirectory:YES];
    NSURL* bundledVfs = [NSBundle.mainBundle URLForResource:@"vfs" withExtension:nil];
    [NSFileManager.defaultManager copyItemAtURL:bundledVfs toURL:vfs error:nil];
}

- (void)setupAudio {
    [AVAudioSession.sharedInstance setCategory:(AVAudioSessionCategoryPlayback) mode:(AVAudioSessionModeDefault) options:(0) error:nil];
}

@end
