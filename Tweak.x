#import <UIKit/UIKit.h>

static UIWindow *floatWindow;
static UIView *floatBall;
static CGPoint touchOffset;

@interface GestureHelper : NSObject
@property (nonatomic, weak) UIView *ball;
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
    NSLog(@"[GlobalGestureTool] ✅ 单击触发回放");
    // ========== 【这里写你的回放代码，不要用变量名 sender！】 ==========
    // IOHIDTouchSender *touchSender = [IOHIDTouchSender sharedInstance];
    // [touchSender 你的回放方法];
}
- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    if(sender.state == UIGestureRecognizerStateBegan) {
        NSLog(@"[GlobalGestureTool] ✅ 长按开始录制");
        // ========== 【这里写开始录制代码】 ==========
        // IOHIDTouchSender *touchSender = [IOHIDTouchSender sharedInstance];
        // [touchSender 开始录制方法];
    } else if(sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"[GlobalGestureTool] ✅ 长按结束录制");
        // ========== 【这里写停止录制代码】 ==========
        // IOHIDTouchSender *touchSender = [IOHIDTouchSender sharedInstance];
        // [touchSender 停止录制方法];
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