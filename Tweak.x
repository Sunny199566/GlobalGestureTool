#import <UIKit/UIKit.h>
#import "IOHIDTouch.h"

// === 悬浮窗点击回调，这就是你需要的【单击悬浮球运行脚本】===
void onFloatButtonTap() {
    NSLog(@"[GlobalGestureTool] Float button tapped, start replay script");

    // 这里后续改成：从本地JSON读取你录制好的脚本数组，现在是示例空脚本
    NSArray<GGTouchFrame*> *loadedScript = [self loadScriptFromFile:@"/var/jb/Library/GlobalGestureTool/default.json"];
    [[IOHIDTouchSender sharedInstance] runScript:loadedScript];
}

// 后续把RemoteCompanion悬浮View的tapGestureRecognizer的action绑定到 onFloatButtonTap
%hook SpringBoard
- (void)applicationDidFinishLaunching {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 在这里初始化悬浮球UI（直接复用RemoteCompanion的悬浮窗口代码）
    });
}
%end