#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

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
static NSString *g_selectedScriptPath = nil;

static void checkSelectedScript() {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *path = [ud stringForKey:@"GesturePlayer_SelectedScriptPath"];
    if (path && ![path isEqualToString:g_selectedScriptPath]) {
        g_selectedScriptPath = path;
    }
}

static void playGesture() {
    if (g_playing || !g_selectedScriptPath) return;
    
    NSData *fileData = [NSData dataWithContentsOfFile:g_selectedScriptPath];
    if (!fileData || fileData.length < sizeof(GestureHeader)) return;

    GestureHeader hdr;
    [fileData getBytes:&hdr range:NSMakeRange(0, sizeof(GestureHeader))];
    if (hdr.magic != 0x47474553) return;

    CGSize curScreenSize = [UIScreen mainScreen].bounds.size;
    uint8_t curOrient = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? 1 : 0;
    if (curOrient != hdr.orientation) {
        NSLog(@"[PlayDaemon] ❌ 屏幕方向不匹配，禁止播放");
        return;
    }

    g_playing = YES;
    NSUInteger offset = sizeof(GestureHeader);
    NSUInteger evSize = sizeof(TouchEvent);
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        while (offset + evSize <= fileData.length && g_playing) {
            TouchEvent ev;
            [fileData getBytes:&ev range:NSMakeRange(offset, evSize)];
            offset += evSize;

            usleep((useconds_t)(ev.delayNanos / 1000));
        }
        g_playing = NO;
    });
}

static void setupFloatWindow() {
    g_floatWin = [[UIWindow alloc] initWithFrame:CGRectMake(10, 250, 55, 55)];
    g_floatWin.windowLevel = UIWindowLevelStatusBar + 9999;
    g_floatWin.hidden = NO;
    
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    playBtn.frame = g_floatWin.bounds;
    playBtn.backgroundColor = [UIColor systemBlueColor];
    playBtn.layer.cornerRadius = 27.5f;
    [playBtn setTitle:@"▶" forState:UIControlStateNormal];
    [playBtn addTarget:nil action:@selector(playGesture) forControlEvents:UIControlEventTouchUpInside];
    [g_floatWin addSubview:playBtn];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            setupFloatWindow();
            [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer * _Nonnull timer) {
                checkSelectedScript();
            }];
        });
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}