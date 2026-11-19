#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController
@property (nonatomic, strong) UIButton *recordBtn;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIButton *stopBtn;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    CGFloat btnWidth = 220;
    CGFloat btnHeight = 50;
    CGFloat yOffset = self.view.bounds.size.height / 2 - 120;
    
    self.recordBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.recordBtn.frame = CGRectMake((self.view.bounds.size.width - btnWidth)/2, yOffset, btnWidth, btnHeight);
    [self.recordBtn setTitle:@"开始录制手势" forState:UIControlStateNormal];
    self.recordBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.recordBtn.backgroundColor = [UIColor systemBlueColor];
    [self.recordBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.recordBtn.layer.cornerRadius = 12;
    [self.recordBtn addTarget:self action:@selector(startRecordAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.recordBtn];
    
    self.playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.playBtn.frame = CGRectMake((self.view.bounds.size.width - btnWidth)/2, yOffset + 70, btnWidth, btnHeight);
    [self.playBtn setTitle:@"回放手势" forState:UIControlStateNormal];
    self.playBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.playBtn.backgroundColor = [UIColor systemGreenColor];
    [self.playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.playBtn.layer.cornerRadius = 12;
    [self.playBtn addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playBtn];
    
    self.stopBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.stopBtn.frame = CGRectMake((self.view.bounds.size.width - btnWidth)/2, yOffset + 140, btnWidth, btnHeight);
    [self.stopBtn setTitle:@"停止全部" forState:UIControlStateNormal];
    self.stopBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.stopBtn.backgroundColor = [UIColor systemRedColor];
    [self.stopBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.stopBtn.layer.cornerRadius = 12;
    [self.stopBtn addTarget:self action:@selector(stopAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.stopBtn];
}

- (void)startRecordAction:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"录制已启动（底层触摸采集逻辑需要对接PlayDaemon守护进程）" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)playAction:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"回放已启动，由PlayDaemon执行触摸模拟" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)stopAction:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"录制/回放已停止" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    MainViewController *rootVC = [[MainViewController alloc] init];
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];
    return YES;
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}