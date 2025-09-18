#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  self.videoWindows = [NSMutableArray array];
  [self setupStatusBar];

  // 防止 App Nap 导致休眠后播放器被挂起
  [[NSProcessInfo processInfo]
      beginActivityWithOptions:NSActivityUserInitiatedAllowingIdleSystemSleep
                        reason:@"Keep video wallpaper running"];

  // 监听唤醒通知
  [[[NSWorkspace sharedWorkspace] notificationCenter]
      addObserver:self
         selector:@selector(handleWake:)
             name:NSWorkspaceDidWakeNotification
           object:nil];
}

- (void)handleWake:(NSNotification *)notification {
  NSLog(@"System woke up, resuming video wallpaper...");

  if (self.player) {
    // 继续播放
    [self.player seekToTime:self.player.currentTime
            toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero];
    [self.player play];
  }

  // 确保窗口层级不丢失
  for (NSWindow *win in self.videoWindows) {
    [win setLevel:(NSInteger)CGWindowLevelForKey(kCGDesktopWindowLevelKey)];
    [win orderBack:nil];
  }
}

// 状态栏

- (void)setupStatusBar {
  self.statusItem = [[NSStatusBar systemStatusBar]
      statusItemWithLength:NSSquareStatusItemLength];
  self.statusItem.button.title = @"🎬";

  NSMenu *menu = [[NSMenu alloc] init];
  [menu addItemWithTitle:@"Select video"
                  action:@selector(selectVideo)
           keyEquivalent:@""];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItemWithTitle:@"Quit" action:@selector(quitApp) keyEquivalent:@""];

  self.statusItem.menu = menu;
}

- (void)selectVideo {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowedContentTypes = @[
    UTTypeMPEG4Movie, UTTypeQuickTimeMovie, UTTypeAVI, UTTypeMPEG, UTTypeVideo
  ];
  panel.canChooseFiles = YES;
  panel.canChooseDirectories = NO;

  [panel beginWithCompletionHandler:^(NSModalResponse result) {
    if (result == NSModalResponseOK) {
      NSURL *url = panel.URL;
      [self playVideo:url];
    }
  }];
}

- (void)quitApp {
  [NSApp terminate:nil];
}

// 播放视频

- (NSImage *)firstFrameImageFromVideoURL:(NSURL *)url {
  __block NSImage *result = nil;
  dispatch_semaphore_t sema = dispatch_semaphore_create(0);

  AVAsset *asset = [AVAsset assetWithURL:url];
  AVAssetImageGenerator *generator =
      [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
  generator.appliesPreferredTrackTransform = YES;

  CMTime time = CMTimeMake(0, 1);

  [generator
      generateCGImagesAsynchronouslyForTimes:@[ [NSValue valueWithCMTime:time] ]
                           completionHandler:^(
                               CMTime requestedTime, CGImageRef cgImage,
                               CMTime actualTime, AVAssetImageGeneratorResult r,
                               NSError *error) {
                             if (r == AVAssetImageGeneratorSucceeded &&
                                 cgImage) {
                               result = [[NSImage alloc]
                                   initWithCGImage:cgImage
                                              size:NSMakeSize(
                                                       CGImageGetWidth(cgImage),
                                                       CGImageGetHeight(
                                                           cgImage))];
                             } else {
                               NSLog(@"Failed to get the first frame of the "
                                     @"video: %@",
                                     error);
                             }
                             dispatch_semaphore_signal(sema);
                           }];

  dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
  return result;
}

- (void)setDesktopImage:(NSImage *)image {
  NSError *error = nil;
  NSArray<NSScreen *> *screens = [NSScreen screens];

  for (NSScreen *screen in screens) {
    NSString *fileName =
        [NSString stringWithFormat:@"wallpaper_%f.png",
                                   [NSDate timeIntervalSinceReferenceDate]];
    NSURL *tmpFileURL =
        [NSURL fileURLWithPath:[NSTemporaryDirectory()
                                   stringByAppendingPathComponent:fileName]];

    CGImageRef cgImage = [image CGImageForProposedRect:NULL
                                               context:nil
                                                 hints:nil];
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    NSData *data = [rep representationUsingType:NSBitmapImageFileTypePNG
                                     properties:@{}];
    [data writeToURL:tmpFileURL atomically:YES];

    BOOL success = [[NSWorkspace sharedWorkspace] setDesktopImageURL:tmpFileURL
                                                           forScreen:screen
                                                             options:@{}
                                                               error:&error];
    if (!success || error) {
      NSLog(@"Failed to set the desktop wallpaper: %@", error);
    }
  }
}

- (void)playVideo:(NSURL *)url {
  NSImage *firstFrame = [self firstFrameImageFromVideoURL:url];
  if (firstFrame) {
    [self setDesktopImage:firstFrame];
  }

  // 停止旧视频
  if (self.player) {
    [self.player pause];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    for (NSWindow *win in self.videoWindows) {
      [win orderOut:nil];
    }
    [self.videoWindows removeAllObjects];
  }

  // 创建 AVPlayer
  self.player = [AVPlayer playerWithURL:url];
  self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;

  // 循环播放
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(loopVideo:)
             name:AVPlayerItemDidPlayToEndTimeNotification
           object:self.player.currentItem];

  // 为每个屏幕创建窗口
  for (NSScreen *screen in [NSScreen screens]) {
    NSRect frame = screen.frame;
    NSWindow *win =
        [[NSWindow alloc] initWithContentRect:frame
                                    styleMask:NSWindowStyleMaskBorderless
                                      backing:NSBackingStoreBuffered
                                        defer:NO];

    // 桌面层级
    [win setLevel:(NSInteger)CGWindowLevelForKey(kCGDesktopWindowLevelKey)];
    [win setOpaque:NO];
    [win setBackgroundColor:[NSColor clearColor]];
    [win setIgnoresMouseEvents:YES];

    // 固定在桌面并显示在所有空间
    win.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
                             NSWindowCollectionBehaviorStationary |
                             NSWindowCollectionBehaviorIgnoresCycle;

    [win makeKeyAndOrderFront:nil];

    // Layer-backed view
    [win.contentView setWantsLayer:YES];

    // 创建 AVPlayerLayer
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    layer.frame = win.contentView.bounds;
    layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [win.contentView.layer addSublayer:layer];

    [self.videoWindows addObject:win];
  }

  [self.player play];
}

- (void)loopVideo:(NSNotification *)notification {
  [self.player seekToTime:kCMTimeZero];
  [self.player play];
}

@end
