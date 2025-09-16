#import <AVKit/AVKit.h>
#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property(strong, nonatomic) NSStatusItem *statusItem;

// 每个屏幕都有一个窗口
@property(strong, nonatomic) NSMutableArray<NSWindow *> *videoWindows;
@property(strong, nonatomic) AVPlayer *player;

- (void)playVideo:(NSURL *)url;

@end
