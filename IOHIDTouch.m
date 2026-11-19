#import "IOHIDTouch.h"
#import <IOKit/hid/IOHIDEvent.h>
#import <Foundation/Foundation.h>

// ========= iOS17 IOHIDDigitizer 私有函数前向声明 =========
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

@implementation IOHIDTouchSender {
    NSMutableArray *_recordBuffer;
    NSTimeInterval _lastFrameTime;
}
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static IOHIDTouchSender *inst;
    dispatch_once(&onceToken, ^{
        inst = [[self alloc] init];
    });
    return inst;
}

- (instancetype)init {
    self = [super init];
    if(self){
        _recordBuffer = [NSMutableArray array];
        _isRecording = NO;
    }
    return self;
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

#pragma mark - Record Logic
- (void)startRecord {
    _isRecording = YES;
    [_recordBuffer removeAllObjects];
    _lastFrameTime = [[NSDate date] timeIntervalSince1970] * 1000;
    NSLog(@"[GlobalGestureTool] 🎬 录制已开始");
}

- (void)stopRecordAndSaveToPath:(NSString *)filePath {
    _isRecording = NO;
    NSMutableArray *jsonArr = [NSMutableArray array];
    for(GGTouchFrame *f in _recordBuffer){
        [jsonArr addObject:[f toDictionary]];
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArr options:NSJSONWritingPrettyPrinted error:nil];
    [jsonData writeToFile:filePath atomically:YES];
    NSLog(@"[GlobalGestureTool] ✅ 录制完成，脚本保存至 %@", filePath);
}

- (void)addRecordFrameX:(CGFloat)x y:(CGFloat)y phase:(GGTouchPhase)phase {
    if(!_isRecording) return;
    NSTimeInterval nowMs = [[NSDate date] timeIntervalSince1970] * 1000;
    GGTouchFrame *frame = [[GGTouchFrame alloc] init];
    frame.fingerOffset = 0; //回放固定使用虚拟手指偏移0 → FingerID=4
    frame.phase = phase;
    frame.x = x;
    frame.y = y;
    frame.delayMs = nowMs - _lastFrameTime;
    _lastFrameTime = nowMs;
    [_recordBuffer addObject:frame];
}

@end