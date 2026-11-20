#import <UIKit/UIKit.h>
#import "IOHIDTouch.h"

static UIView *floatBall;
static CGPoint touchStartPoint;
static BOOL isDragging;

@interface GestureTargetHelper : NSObject
@property (nonatomic, assign) UIView *floatBall;
- (void)onFloatButtonTap:(UITapGestureRecognizer *)gesture;
- (void)onFloatButtonLongPress:(UILongPressGestureRecognizer *)gesture;
- (void)handlePan:(UIPanGestureRecognizer *)gesture;
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

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *ball = self.floatBall;
    CGPoint point = [gesture translationInView:ball.superview];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        touchStartPoint = ball.center;
        isDragging = NO;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        ball.center = CGPointMake(touchStartPoint.x + point.x, touchStartPoint.y + point.y);
        isDragging = YES;
    }
}
@end

static GestureTargetHelper *gestureTarget;

%hook SpringBoard
- (void)applicationDidFinishLaunching {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(floatBall) return;
        UIView *rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        if(!rootView) return;
        
        gestureTarget = [[GestureTargetHelper alloc] init];
        CGFloat ballSize = 60;
        floatBall = [[UIView alloc] initWithFrame:CGRectMake(30, 300, ballSize, ballSize)];
        floatBall.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.75];
        floatBall.layer.cornerRadius = ballSize / 2.0;
        floatBall.layer.masksToBounds = YES;
        gestureTarget.floatBall = floatBall;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:gestureTarget action:@selector(onFloatButtonTap:)];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:gestureTarget action:@selector(onFloatButtonLongPress:)];
        longPress.minimumPressDuration = 0.5;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:gestureTarget action:@selector(handlePan:)];
        
        [floatBall addGestureRecognizer:tap];
        [floatBall addGestureRecognizer:longPress];
        [floatBall addGestureRecognizer:pan];
        
        [rootView addSubview:floatBall];
        NSLog(@"[GlobalGestureTool] ✅ 悬浮球已经添加到SpringBoard根视图");
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