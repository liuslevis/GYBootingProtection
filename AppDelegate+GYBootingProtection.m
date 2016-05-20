//
//  AppDelegate+GYBootingProtection.m
//  WeRead
//
//  Created by richliu on 16/5/19.
//

#import "AppDelegate+GYBootingProtection.h"
#import "AppDelegate.h"
#import "GYBootingProtection.h"
#import "UIAlertView+Blocks.h"

static NSString *const fixButtonTitle = @"修复";
static NSString *const cancelFixButtonTitle = @"取消";
static NSString *const createCrashButtonTitle = @"制造Crash!";

@implementation AppDelegate (GYBootingProtection)

/*
 * TODO 连续闪退检测前需要执行的逻辑，如上报统计初始化
 */
- (void)onBeforeBootingProtection {    
    // 制造 crash 彩蛋
//    [GYBootingProtection setStartupCrashForTest:YES];
    [self showAlertForCreateCrashIfNeeded];
}

/*
 * TODO 修复完成后的逻辑，比如退出登录
 */
- (void)didFinishBootingProtection {

}

/**
 * 连续闪退检测逻辑，Method Swizzle 了原来 didFinishLaunch。
 * 如果检测到连续闪退，提示用户进行修复
 */
- (BOOL)swizzled_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self onBeforeBootingProtection];
    
    /* ------- 启动连续闪退保护 ------- */
    [GYBootingProtection setLogger:^(NSString *msg) {
        // 设置Logger
        GYLOG(Log_BootingProtection, @"%@", msg);
    }];
    RepairBlock repairBlock = ^void(BoolCompletionBlock completion) {
        // 修复逻辑
        [self showAlertForFixContinuousCrashOnCompletion:completion];
    };
    ReportBlock reportBlock = ^void(NSInteger crashCounts) {
        // 上报逻辑
        [[CrashReporter sharedInstance] checkAndUpload];
    };
    BoolCompletionBlock completion = ^BOOL() {
        // 正常启动逻辑
        return [self swizzled_application:application didFinishLaunchingWithOptions:launchOptions];
    };
    return [GYBootingProtection launchContinuousCrashProtectWithReportBlock:reportBlock repairBlock:repairBlock completion:completion];
}

#pragma mark - 修复启动连续 Crash 逻辑
/**
 * 弹Tip询问用户是否修复连续 Crash
 * @param BoolCompletionBlock 无论用户是否修复，最后执行该 block 一次
 */
- (void)showAlertForFixContinuousCrashOnCompletion:(BoolCompletionBlock)completion {
    GYLOG(Log_BootingProtection, @"Detect continuous crash %ld times. Prompt user to fix.",  (long)[GYBootingProtection crashCount]);
    NSString *title = [NSString stringWithFormat:@"提示"];
    NSString *message = @"检测到应用可能已损坏，是否尝试修复？";
    @weakify(self);
    [UIAlertView showWithTitle:title
                       message:message
             cancelButtonTitle:cancelFixButtonTitle
             otherButtonTitles:@[fixButtonTitle]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex)
     {
         @strongify(self);
         if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:cancelFixButtonTitle]) {
             if (completion) completion();
             
         } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:fixButtonTitle]) {
             [self tryToFixContinuousCrash:^void{
                 if (completion) completion();
             }];
         }
         
     }];
}

/**
 * 弹Tip询问用户是否制造 Crash
 */
- (void)showAlertForCreateCrashIfNeeded {
    if ([GYBootingProtection startupCrashForTest]) {
        NSString *title = @"制造一个 Crash ？";
        NSString *message = [NSString stringWithFormat:@"已经连续 crash 了%ld 次\n可以在设置彩蛋取消这个提示", [GYBootingProtection crashCount]];
        [UIAlertView showWithTitle:title
                           message:message
                 cancelButtonTitle:cancelFixButtonTitle
                 otherButtonTitles:@[createCrashButtonTitle]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex)
         {
             if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:createCrashButtonTitle]) {
                 [WRRqdHelper testSignalError];
                 //                 [WRRqdHelper testNSException];
             }
         }];
    }
}

- (void)tryToFixContinuousCrash:(void(^)(void))completion
{
    BOOL checkJSPatch = NO;
    
    if (!checkJSPatch) {
        [self tryToFixWithLocalLogic];
        [self didFinishBootingProtection]
    } else {
        // 先拉检查 JSPatch 更新，再执行本地修复逻辑
        [WRFeatureManager syncFeature:[GYUICallback callbackWithSuccess:^(id data) {
            [self tryToFixWithLocalLogic];
            [self didFinishBootingProtection]
            if (completion) completion();
        } withError:^(NSError *error) {
            [self tryToFixWithLocalLogic];
            if (completion) completion();
        }]];
    }
}

- (void)tryToFixWithLocalLogic {
    // 删除Document Library Caches所有文件
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];

    NSArray *filePathsToRemove = @[documentsDirectory, libraryDirectory, cachesDirectory];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    for (NSString *filePath in filePathsToRemove) {
        if ([fileMgr fileExistsAtPath:filePath]) {
            NSArray *subFileArray = [fileMgr contentsOfDirectoryAtPath:filePath error:nil];
            for (NSString *subFileName in subFileArray) {
                NSString *subFilePath = [filePath stringByAppendingPathComponent:subFileName];
                if ([fileMgr removeItemAtPath:subFilePath error:nil]) {
                    NSLog(@"removed file path:%@", subFilePath);
                } else {
                    NSLog(@"failed to remove file path:%@", subFilePath);
                }
            }
        } else {
            NSLog(@"failed to remove non-existing file path:%@", filePath);
        }
    }
    
    NSLog(@"recoverFromContinuousCrash finished, files at home:[%@]\nDocuments:[%@]\nLibrary:[%@]\ntmp:[%@]",
          [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[GYFileUtils homeDirectoryPath] error:nil],
          [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[GYFileUtils documentDirectoryPath] error:nil],
          [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[GYFileUtils LibraryDirectoryPath] error:nil],
          [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[GYFileUtils tempDirectoryPath] error:nil]);
}

#pragma mark - Method Swizzling
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [super class];
        
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        
        SEL originalSelector = @selector(application:didFinishLaunchingWithOptions:);
        SEL swizzledSelector = @selector(swizzled_application:didFinishLaunchingWithOptions:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

@end
