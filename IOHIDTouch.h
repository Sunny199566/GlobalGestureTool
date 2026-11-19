#ifndef IOHIDTouch_h
#define IOHIDTouch_h
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

// ========== 核心配置：虚拟手指起始ID，避开真实手指0~3 ==========
#define VIRTUAL_FINGER_BASE_ID   4
#define MAX_VIRTUAL_FINGER       3

typedef NS_ENUM(NSInteger, GGTouchPhase) {
    GGTouchPhaseDown,
    GGTouchPhaseMove,
    GGTouchPhaseUp
};

@interface GGTouchFrame : NSObject
@property (nonatomic, assign) NSInteger fingerOffset;
@property (nonatomic, assign) GGTouchPhase phase;
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) NSTimeInterval delayMs;
- (NSDictionary *)toDictionary;
+ (GGTouchFrame *)fromDictionary:(NSDictionary *)dict;
@end

@interface IOHIDTouchSender : NSObject
+ (instancetype)sharedInstance;
- (void)sendTouchWithFingerOffset:(NSInteger)offset
                            phase:(GGTouchPhase)phase
                               x:(CGFloat)x y:(CGFloat)y;
- (void)runScript:(NSArray<GGTouchFrame*> *)scriptFrames;
- (NSArray<GGTouchFrame*> *)loadScriptFromFile:(NSString *)path;

// ========== 录制新增接口 ==========
@property (nonatomic, assign) BOOL isRecording;
- (void)startRecord;
- (void)stopRecordAndSaveToPath:(NSString *)filePath;
- (void)addRecordFrameX:(CGFloat)x y:(CGFloat)y phase:(GGTouchPhase)phase;
@end

#endif