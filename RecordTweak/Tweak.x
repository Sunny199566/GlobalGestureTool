%config(generator=libhooker)
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef NS_ENUM(uint8_t, TouchEvType) {
    TEV_DOWN = 0,
    TEV_MOVE = 1,
    TEV_UP = 2
};

typedef struct {
    uint32_t magic;          // 0x47474553 "GGES"
    uint16_t screenW;
    uint16_t screenH;
    uint8_t  orientation;     //1=横屏,0=竖屏
    uint8_t  reserved[3];
    uint32_t eventCount;
} GestureHeader;

typedef struct {
    uint8_t type;
    uint8_t fingerId;
    float x;
    float y;
    uint64_t delayNanos;
} TouchEvent;

static BOOL g_recording = NO;
static NSMutableData *g_recordRawData;
static uint64_t g_lastTs;
static UIWindow *g_floatWindow;
static UIButton *g_floatBtn;
static NSString *g_scriptName;

static uint64_t getBootNsTime() {
    return clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW);
}

static NSString *globalScriptDir() {
    return @"/var/jb/GlobalGestures";
}

static void makeDir() {
    [[NSFileManager defaultManager] createDirectoryAtPath:globalScriptDir()
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
}

static void startRecord() {
    g_recording = YES;
    g_recordRawData = [NSMutableData new];
    g_lastTs = getBootNsTime();
    g_scriptName = [NSString stringWithFormat:@"script_%llu.dat", getBootNsTime()];
    NSLog(@"[RecordTweak] 开始录制手势");
    dispatch_async(dispatch_get_main_queue(), ^{
        g_floatBtn.backgroundColor = [UIColor orangeColor];
    });
}

static void stopAndSave() {
    g_recording = NO;
    if(g_recordRawData.length == 0) return;
    makeDir();

    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    uint8_t orient = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? 1 : 0;

    GestureHeader hdr;
    hdr.magic = 0x47474553;
    hdr.screenW = (uint16_t)screenSize.width;
    hdr.screenH = (uint16_t)screenSize.height;
    hdr.orientation = orient;
    memset(hdr.reserved, 0, sizeof(hdr.reserved));
    hdr.eventCount = (uint32_t)(g_recordRawData.length / sizeof(TouchEvent));

    NSMutableData *finalData = [NSMutableData new];
    [finalData appendBytes:&hdr length:sizeof(GestureHeader)];
    [finalData appendData:g_recordRawData];

    NSString *savePath = [globalScriptDir() stringByAppendingPathComponent:g_scriptName];
    [finalData writeToFile:savePath atomically:YES];

    NSLog(@"[RecordTweak] 脚本保存成功 %@", savePath);
    dispatch_async(dispatch_get_main_queue(), ^{
        g_floatBtn.backgroundColor = [UIColor systemRedColor];
    });

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:g_scriptName forKey:@"GestureRecord_Finish_Name"];
    [ud setBool:YES forKey:@"GestureRecord_Finish"];
    [ud synchronize];
}

static void appendTouchEvent(TouchEvType type, uint8_t fid, float x, float y) {
    if (!g_recording) return;
    uint64_t now = getBootNsTime();
    TouchEvent ev;
    ev.type = type;
    ev.fingerId = fid;
    ev.x = x;
    ev.y = y;
    ev.delayNanos = now - g_lastTs;
    g_lastTs = now;
    [g_recordRawData appendBytes:&ev length:sizeof(TouchEvent)];
}

static void floatBtnTap() {
    if (!g_recording) {
        startRecord();
    } else {
        stopAndSave();
    }
}

static void setupFloatWindow() {
    g_floatWindow = [[UIWindow alloc] initWithFrame:CGRectMake(20, 300, 60, 60)];
    g_floatWindow.windowLevel = UIWindowLevelAlert + 10;
    g_floatWindow.hidden = NO;
    g_floatBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    g_floatBtn.frame = g_floatWindow.bounds;
    g_floatBtn.backgroundColor = [UIColor systemRedColor];
    g_floatBtn.layer.cornerRadius = 30;
    [g_floatBtn setTitle:@"REC" forState:UIControlStateNormal];
    [g_floatBtn addTarget:nil action:@selector(floatBtnTap) forControlEvents:UIControlEventTouchUpInside];
    [g_floatWindow addSubview:g_floatBtn];
}

%ctor {
    dispatch_async(dispatch_get_main_queue(), ^{
        setupFloatWindow();
    });
}

%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;
    if(!g_recording) return;
    for(UITouch *touch in event.allTouches) {
        CGPoint pt = [touch locationInView:nil];
        TouchEvType t;
        switch(touch.phase) {
            case UITouchPhaseBegan: t = TEV_DOWN; break;
            case UITouchPhaseMoved: t = TEV_MOVE; break;
            case UITouchPhaseEnded: t = TEV_UP; break;
            default: continue;
        }
        appendTouchEvent(t, touch.touchIdentifier, pt.x, pt.y);
    }
}
%end