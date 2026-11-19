#import "IOHIDTouch.h"
#import <IOKit/hid/IOHIDEvent.h>
#import <Foundation/Foundation.h>

// ========= iOS17 IOHIDDigitizer 私有函数前向声明（解决未定义报错） =========
typedef CFTypeRef IOHIDDigitizerEventRef;
IOHIDDigitizerEventRef IOHIDDigitizerEventCreate(CFAllocatorRef alloc, NSInteger fingerID);
void IOHIDDigitizerEventSetPosition(IOHIDDigitizerEventRef event, CGPoint pt);
void IOHIDDigitizerEventSetIsTouching(IOHIDDigitizerEventRef event, Boolean touching);
void IOHIDDigitizerEventSetTouchType(IOHIDDigitizerEventRef event, int type);

#define kIOHIDDigitizerEventTouchTypeFinger 0

@implementation GGTouchFrame
- (NSDictionary *)toDictionary {
    return @{
        @"fingerOffset": @(self.fingerOffset),
        @"phase": @(self.phase),
        @"x": @(self.x),
        @"y": @(self.y),
        @"delayMs": @(self.delayMs)
    };
}
+ (GGTouchFrame *)fromDictionary:(NSDictionary *)dict {
    GGTouchFrame *frame = [[GGTouchFrame alloc] init];
    frame.fingerOffset = [dict[@"fingerOffset"] integerValue];
    frame.phase = [dict[@"phase"] integerValue];
    frame.x = [dict[@"x"] doubleValue];
    frame.y = [dict[@"y"] doubleValue];
    frame.delayMs = [dict[@"delayMs"] doubleValue];
    return frame;
}
@end

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
    IOHIDDigitizerEventRef event = IOHIDDigitizerEventCreate(kCFAllocatorDefault, fingerID);
    if (!event) return;

    IOHIDDigitizerEventSetPosition(event, CGPointMake(x, y));
    IOHIDDigitizerEventSetTouchType(event, kIOHIDDigitizerEventTouchTypeFinger);
    IOHIDDigitizerEventSetIsTouching(event, (phase == GGTouchPhaseDown || phase == GGTouchPhaseMove));

    IOHIDEventPost((IOHIDEventRef)event, 0);
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

- (NSArray<GGTouchFrame*> *)loadScriptFromFile:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) return @[];
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return @[];
    NSArray *raw = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![raw isKindOfClass:[NSArray class]]) return @[];

    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *item in raw) {
        [result addObject:[GGTouchFrame fromDictionary:item]];
    }
    return result.copy;
}
@end