#import <UIKit/UIKit.h>
#import "IOHIDTouch.h"

static UIWindow *floatWindow;
static UIView *floatBall;
static CGPoint touchStartPoint;
static BOOL isDragging;

// ✅ 手势Target辅助类
@interface GestureTargetHelper : NSObject
- (void)onFloatButtonTap:(UITapGestureRecognizer *)gesture;
- (void)onFloatButtonLongPress:(UILongPressGestureRecognizer *)gesture;
@end

@implementation GestureTargetHelper
- (void)onFloatButtonTap:(UITapGestureRecognizer *)gesture {
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
- (void)onFloatButtonLongPress:(UILongPressGestureRecognizer *)gesture {
    IOHIDTouchSender *sender = [IOHIDTouchSender sharedInstance];
    NSString *scriptPath = @"/var/jb/Library/GlobalGestureTool/default.json";
    if(sender.isRecording){
        [sender stopRecordAndSaveToPath:scriptPath];
    }else{
        [sender startRecord];
    }
}
@end

static GestureTargetHelper *gestureTarget;

%hook SpringBoard
- (void)applicationDidFinishLaunching {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(floatWindow) return;
        
        floatWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        floatWindow.windowLevel = 10000000;
        floatWindow.backgroundColor = [UIColor clearColor];
        floatWindow.hidden = NO;
        
        CGFloat ballSize = 60;
        floatBall = [[UIView alloc] initWithFrame:CGRectMake(30, 300, ballSize, ballSize)];
        floatBall.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.75];
        floatBall.layer.cornerRadius = ballSize / 2.0;
        floatBall.layer.masksToBounds = YES;

        // ✅ 创建手势target实例
        gestureTarget = [[GestureTargetHelper alloc] init];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:gestureTarget action:@selector(onFloatButtonTap:)];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:gestureTarget action:@selector(onFloatButtonLongPress:)];
        longPress.minimumPressDuration = 0.5;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:floatBall action:@selector(handlePan:)];
        
        [floatBall addGestureRecognizer:tap];
        [floatBall addGestureRecognizer:longPress];
        [floatBall addGestureRecognizer:pan];
        
        [floatWindow addSubview:floatBall];
        NSLog(@"[GlobalGestureTool] ✅ 悬浮窗口加载完成");
    });
}
%end

// Hook UIApplication 触摸事件捕获，录制触摸坐标
%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;
    if(event.type == UIEventTypeTouches){
        NSSet *touches = [event allTouches];
        IOHIDTouchSender *sender = [IOHIDTouchSender sharedInstance];
        if(!sender.isRecording) return;
        for(UITouch *t in touches){
            CGPoint pt = [t locationInView:nil];
            GGTouchPhase p;
            switch (t.phase) {
                case UITouchPhaseBegan: p = GGTouchPhaseDown; break;
                case UITouchPhaseMoved: p = GGTouchPhaseMove; break;
                case UITouchPhaseEnded: p = GGTouchPhaseUp; break;
                default: continue;
            }
            [sender addRecordFrameX:pt.x y:pt.y phase:p];
        }
    }
}
%end

@interface UIView (GesturePrivate)
- (void)handlePan:(UIPanGestureRecognizer *)gesture;
@end
@implementation UIView (GesturePrivate)
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *ball = gesture.view;
    // ✅ 修复 translationInView 参数，传入nil
    CGPoint point = [gesture translationInView:nil];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        touchStartPoint = ball.center;
        isDragging = NO;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        ball.center = CGPointMake(touchStartPoint.x + point.x, touchStartPoint.y + point.y);
        isDragging = YES;
    }
}
@end