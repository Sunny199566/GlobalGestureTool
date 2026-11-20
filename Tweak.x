#import <UIKit/UIKit.h>
#import "IOHIDTouch.h"

static UIWindow *floatWindow;
static UIView *floatBall;
static CGPoint touchOffset;

@interface GestureHelper : NSObject
@property (nonatomic, assign) UIView *ball;
- (void)panAction:(UIPanGestureRecognizer *)sender;
- (void)tapAction:(UITapGestureRecognizer *)sender;
- (void)longPressAction:(UILongPressGestureRecognizer *)sender;
@end

@implementation GestureHelper
- (void)panAction:(UIPanGestureRecognizer *)sender {
    UIView *ball = self.ball;
    if (!ball) return;
    if(sender.state == UIGestureRecognizerStateBegan) {
        touchOffset = [sender locationInView:ball];
    } else if(sender.state == UIGestureRecognizerStateChanged) {
        CGPoint pt = [sender locationInView:ball.superview];
        CGRect frame = ball.frame;
        frame.origin.x = pt.x - touchOffset.x;
        frame.origin.y = pt.y - touchOffset.y;
        ball.frame = frame;
    }
}
- (void)tapAction:(UITapGestureRecognizer *)sender {
    NSLog(@"[GlobalGestureTool] ✅ 单击：读取脚本并回放");
    IOHIDTouchSender *touchSender = [IOHIDTouchSender sharedInstance];
    NSString *scriptPath = @"/tmp/ggtouch_script.plist";
    NSArray<GGTouchFrame*> *frames = [touchSender loadScriptFromFile:scriptPath];
    if(frames.count > 0) {
        [touchSender runScript:frames];
    }
}
- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    IOHIDTouchSender *touchSender = [IOHIDTouchSender sharedInstance];
    if(sender.state == UIGestureRecognizerStateBegan) {
        NSLog(@"[GlobalGestureTool] ✅ 长按开始录制");
        [touchSender startRecord];
    } else if(sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"[GlobalGestureTool] ✅ 长按结束录制，保存脚本");
        NSString *savePath = @"/tmp/ggtouch_script.plist";
        [touchSender stopRecordAndSaveToPath:savePath];
    }
}
@end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(floatWindow) return;
        floatWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        floatWindow.windowLevel = UIWindowLevelAlert + 9999;
        floatWindow.hidden = NO;
        
        GestureHelper *helper = [GestureHelper new];
        CGFloat size = 60;
        floatBall = [[UIView alloc] initWithFrame:CGRectMake(30,300,size,size)];
        floatBall.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.8];
        floatBall.layer.cornerRadius = size/2.0;
        floatBall.layer.zPosition = 9999999;
        helper.ball = floatBall;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:helper action:@selector(tapAction:)];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:helper action:@selector(panAction:)];
        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:helper action:@selector(longPressAction:)];
        lp.minimumPressDuration = 0.4;
        
        [floatBall addGestureRecognizer:tap];
        [floatBall addGestureRecognizer:pan];
        [floatBall addGestureRecognizer:lp];
        [floatWindow addSubview:floatBall];
        
        NSLog(@"[GlobalGestureTool] ✅ UIWindow悬浮窗口创建成功");
    });
}