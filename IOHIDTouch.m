#import "IOHIDTouch.h"
#import <IOKit/hid/IOHIDServiceClient.h>

@implementation IOHIDTouchSender
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static IOHIDTouchSender *inst;
    dispatch_once(&onceToken, ^{
        inst = [[self alloc] init];
    });
    return inst;
}

- (void)sendTouchWithFingerOffset:(NSInteger)offset phase:(GGTouchPhase)phase x:(CGFloat)x y:(CGFloat)y {
    NSInteger fingerID = VIRTUAL_FINGER_BASE_ID + offset;
    IOHIDDigitizerEventRef event;

    // 创建Digitizer触摸事件，iOS17结构
    event = IOHIDDigitizerEventCreate(kCFAllocatorDefault, fingerID);
    if (!event) return;

    IOHIDDigitizerEventSetPosition(event, CGPointMake(x, y));
    IOHIDDigitizerEventSetTouchType(event, kIOHIDDigitizerEventTouchTypeFinger);

    switch (phase) {
        case GGTouchPhaseDown:
            IOHIDDigitizerEventSetIsTouching(event, true);
            break;
        case GGTouchPhaseMove:
            IOHIDDigitizerEventSetIsTouching(event, true);
            break;
        case GGTouchPhaseUp:
            IOHIDDigitizerEventSetIsTouching(event, false);
            break;
    }

    // 提交事件到系统
    IOHIDEventPost((IOHIDEventRef)event, kIOHIDEventOptionNone);
    CFRelease(event);
}

- (void)runScript:(NSArray<GGTouchFrame*> *)scriptFrames {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (GGTouchFrame *frame in scriptFrames) {
            [self sendTouchWithFingerOffset:frame.fingerOffset phase:frame.phase x:frame.x y:frame.y];
            usleep((useconds_t)(frame.delayMs * 1000));
        }
    });
}
@end