#import <UIKit/UIKit.h>
#import "IOHIDTouch.h"

static UIWindow *floatWindow;
static UIView *floatBall;
static CGPoint touchStartPoint;
static BOOL isDragging;

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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(floatWindow) return;
        
        // 创建悬浮窗口，层级高于普通App，但是非独占，底层触摸可以穿透
        floatWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        floatWindow.windowLevel = 10000000;
        floatWindow.backgroundColor = [UIColor clearColor];
        floatWindow.hidden = NO;
        
        // 悬浮球视图，大小60*60，半透明深色圆形
        CGFloat ballSize = 60;
        floatBall = [[UIView alloc] initWithFrame:CGRectMake(30, 300, ballSize, ballSize)];
        floatBall.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.75];
        floatBall.layer.cornerRadius = ballSize / 2.0;
        floatBall.layer.masksToBounds = YES;
        
        // 添加点击+拖拽手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:&onFloatButtonTap action:@selector(onFloatButtonTap)];
        [floatBall addGestureRecognizer:tap];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:floatBall action:@selector(handlePan:)];
        [floatBall addGestureRecognizer:pan];
        
        [floatWindow addSubview:floatBall];
        NSLog(@"[GlobalGestureTool] ✅ 悬浮窗口加载完成");
    });
}
%end

@interface UIView (GesturePrivate)
- (void)handlePan:(UIPanGestureRecognizer *)gesture;
@end
@implementation UIView (GesturePrivate)
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *ball = gesture.view;
    CGPoint point = [gesture translationInView:[UIScreen mainScreen].bounds];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        touchStartPoint = ball.center;
        isDragging = NO;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        ball.center = CGPointMake(touchStartPoint.x + point.x, touchStartPoint.y + point.y);
        isDragging = YES;
    }
}
@end