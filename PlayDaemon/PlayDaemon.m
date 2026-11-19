#import <Foundation/Foundation.h>

@protocol GestureDaemonProtocol
- (void)startRecord;
- (void)stopRecord;
- (void)playGesture;
@end

@interface DaemonHandler : NSObject <GestureDaemonProtocol>
@end

@implementation DaemonHandler
- (void)startRecord {
    NSLog(@"[Daemon] ✅ 收到指令：开始录制手势");
    // ========== 这里放你的触摸采集底层录制代码 ==========
}
- (void)stopRecord {
    NSLog(@"[Daemon] ✅ 收到指令：停止录制手势");
    // ========== 这里放停止录制底层代码 ==========
}
- (void)playGesture {
    NSLog(@"[Daemon] ✅ 收到指令：回放手势");
    // ========== 这里放触摸回放底层模拟代码 ==========
}
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSXPCListener *listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.globalgesture.gesturemanager.xpc"];
        listener.delegate = [[DaemonHandler alloc] init];
        [listener resume];
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}