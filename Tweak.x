#import <UIKit/UIKit.h>
#import "IOHIDTouch.h"

void onFloatButtonTap() {
    NSLog(@"[GlobalGestureTool] ✅ 悬浮球单击触发，开始回放脚本");
    IOHIDTouchSender *sender = [IOHIDTouchSender sharedInstance];
    NSString *scriptPath = @"/var/jb/Library/GlobalGestureTool/default.json";
    NSArray<GGTouchFrame*> *script = [sender loadScriptFromFile:scriptPath];
    if (script.count == 0) {
        NSLog(@"[GlobalGestureTool] ⚠️ 脚本为空或者文件不存在");
        return;
    }
    [sender runScript:script];
}

%hook SpringBoard
- (void)applicationDidFinishLaunching {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 👉 这里后续粘贴悬浮窗UI代码（RemoteCompanion悬浮球View + tap手势，绑定到onFloatButtonTap）
        NSLog(@"[GlobalGestureTool] Tweak loaded successfully");
    });
}
%end