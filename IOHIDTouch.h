#ifndef IOHIDTouch_h
#define IOHIDTouch_h
#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDEvent.h>
#import <IOKit/hid/IOHIDDigitizerEvent.h>

// ========== 核心配置：独立虚拟手指起始ID，避开真实手指 0,1,2,3 ==========
#define VIRTUAL_FINGER_BASE_ID   4
#define MAX_VIRTUAL_FINGER       3   // 虚拟手指：4,5,6

// 触摸事件类型
typedef NS_ENUM(NSInteger, GGTouchPhase) {
    GGTouchPhaseDown,
    GGTouchPhaseMove,
    GGTouchPhaseUp
};

// 单条录制脚本节点（JSON序列化结构）
@interface GGTouchFrame : NSObject
@property (nonatomic, assign) NSInteger fingerOffset; // 偏移：0 → VIRTUAL_FINGER_BASE_ID +0 =4
@property (nonatomic, assign) GGTouchPhase phase;
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) NSTimeInterval delayMs; // 和上一帧间隔毫秒
@end

@interface IOHIDTouchSender : NSObject
+ (instancetype)sharedInstance;
- (void)sendTouchWithFingerOffset:(NSInteger)offset
                            phase:(GGTouchPhase)phase
                               x:(CGFloat)x y:(CGFloat)y;
- (void)runScript:(NSArray<GGTouchFrame*> *)scriptFrames;
@end

#endif