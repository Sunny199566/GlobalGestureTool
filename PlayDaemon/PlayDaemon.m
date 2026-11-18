#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include <mach/mach_time.h>
#include <dlfcn.h>

typedef void (*GSEventSendRecordedTouchEvent_t)(int touchID, int phase, CGPoint point, double timestamp);
static GSEventSendRecordedTouchEvent_t GSEventSendRecordedTouchEvent = NULL;

typedef struct {
    uint32_t magic;
    uint16_t screenW;
    uint16_t screenH;
    uint8_t  orientation;
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

static UIWindow *g_floatWin;
static BOOL g_playing = NO;
static NSString *g_selectedPath = nil;
static mach_timebase_info_data_t g_timebase;

static double machTimeToSeconds(uint64_t machTime) {
    return (double)machTime * (double)g_timebase.numer / (double)g_timebase.denom / 1e9;
}

static void checkSelectedScript() {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *path = [ud stringForKey:@"GestureScriptPath"];
    if(path && ![path isEqualToString:g_selectedPath]) {
        g_selectedPath = path;
    }
}

static void playGesture() {
    if(g_playing || !g_selectedPath) return;
    if(!GSEventSendRecordedTouchEvent) {
        void *gsHandle = dlopen("/System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices", RTLD_NOW);
        if(gsHandle) {
            GSEventSendRecordedTouchEvent = (GSEventSendRecordedTouchEvent_t)dlsym(gsHandle, "GSEventSendRecordedTouchEvent");
        }
        if(!GSEventSendRecordedTouchEvent) {
            NSLog(@"[PlayDaemon] GSEventSendRecordedTouchEvent symbol not found!");
            return;
        }
    }

    NSData *fileData = [NSData dataWithContentsOfFile:g_selectedPath];
    if(!fileData || fileData.length < sizeof(GestureHeader)) return;

    GestureHeader header;
    [fileData getBytes:&header length:sizeof(GestureHeader)];
    if(header.magic != 0x12345678) return;

    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    uint8_t curOrient = ([UIApplication sharedApplication].statusBarOrientation > UIInterfaceOrientationPortrait) ? 1 : 0;
    if(header.orientation != curOrient) {
        NSLog(@"[PlayDaemon] Orientation mismatch!");
        return;
    }

    g_playing = YES;
    uint64_t startTime = mach_absolute_time();
    NSUInteger offset = sizeof(GestureHeader);
    NSUInteger evSize = sizeof(TouchEvent);

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        while(offset + evSize <= fileData.length && g_playing) {
            TouchEvent ev;
            [fileData getBytes:&ev range:NSMakeRange(offset, evSize)];
            offset += evSize;

            uint64_t targetAbs = startTime + ev.delayNanos * g_timebase.denom / g_timebase.numer;
            while(mach_absolute_time() < targetAbs) usleep(50);

            int phase;
            switch(ev.type) {
                case 0: phase = 0; break;
                case 1: phase = 1; break;
                case 2: phase = 2; break;
                default: phase = 2;
            }
            CGPoint pt = CGPointMake(ev.x, ev.y);
            double ts = machTimeToSeconds(mach_absolute_time());
            GSEventSendRecordedTouchEvent(ev.fingerId, phase, pt, ts);
        }
        g_playing = NO;
    });
}

static void setupFloatUI() {
    g_floatWin = [[UIWindow alloc] initWithFrame:CGRectMake(10,250,55,55)];
    g_floatWin.windowLevel = UIWindowLevelStatusBar + 100;
    g_floatWin.rootViewController = [UIViewController new];
    g_floatWin.hidden = NO;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = g_floatWin.bounds;
    btn.backgroundColor = [UIColor systemBlueColor];
    btn.layer.cornerRadius = 27.5;
    [btn setTitle:@"▶" forState:UIControlStateNormal];
    [btn addTarget:nil action:@selector(playGesture) forControlEvents:UIControlEventTouchUpInside];
    [g_floatWin addSubview:btn];
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        mach_timebase_info(&g_timebase);
        setupFloatUI();
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer * _Nonnull timer) {
            checkSelectedScript();
        }];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}