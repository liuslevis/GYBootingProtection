//
//  AppDelegate+GYBootingProtection.m
//  WeRead
//
//  Created by richliu on 16/5/19.
//

#import "AppDelegate+GYBootingProtection.h"
#import <objc/runtime.h>
#import "GYBootingProtection.h"

static NSString *const makeCrashAlertTitle = @"制造一个 Crash ？";
static NSString *const fixCrashAlertTitle = @"提示";
static NSString *const fixCrashButtonTitle = @"修复";
static NSString *const cancelButtonTitle = @"取消";
static NSString *const createCrashButtonTitle = @"制造Crash!";

@implementation AppDelegate (GYBootingProtection)

/*
 * 连续闪退检测前需要执行的逻辑，如上报统计初始化
 */
- (void)onBeforeBootingProtection {
    // TODO
    
    // 制造 crash 彩蛋
    [GYBootingProtection setStartupCrashForTest:YES];
    [self showAlertForCreateCrashIfNeeded];
}

/*
 * 修复完成后的逻辑，比如退出登录
 */
- (void)didFinishBootingProtection {
    // TODO
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
        NSLog(@"%@", msg);
    }];
    RepairBlock repairBlock = ^void(BoolCompletionBlock completion) {
        // 修复逻辑
        [self showAlertForFixContinuousCrashOnCompletion:completion];
    };
    ReportBlock reportBlock = ^void(NSInteger crashCounts) {
        // TODO 上报逻辑
        
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
    NSLog(@"Detect continuous crash %ld times. Prompt user to fix.",  (long)[GYBootingProtection crashCount]);
    NSString *message = @"检测到应用可能已损坏，是否尝试修复？";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:fixCrashAlertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (completion) completion();
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:fixCrashButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self tryToFixContinuousCrash:^void{
            if (completion) completion();
        }];
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self.window makeKeyAndVisible];
    [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
}

/**
 * 弹Tip询问用户是否制造 Crash
 */
- (void)showAlertForCreateCrashIfNeeded {
    if ([GYBootingProtection startupCrashForTest]) {
        NSString *message = [NSString stringWithFormat:@"已经连续 crash 了%ld 次\n可以在设置彩蛋取消这个提示", [GYBootingProtection crashCount]];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:makeCrashAlertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:createCrashButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // create crash
            id a = @"demo";
            [a numberOfRowsInSection:0];
        }];
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        [self.window makeKeyAndVisible];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)tryToFixContinuousCrash:(void(^)(void))completion
{
    // TODO 可先检查 JSPatch 更新
    
    // 执行本地修复逻辑
    [self tryToFixWithLocalLogic];
    [self didFinishBootingProtection];
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
    
    NSLog(@"recoverFromContinuousCrash finished, files at home:[%@]\nDocuments:[%@]\nLibrary:[%@]\nCaches:[%@]",
          [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSHomeDirectory() error:nil],
          [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil],
          [[NSFileManager defaultManager] contentsOfDirectoryAtPath:libraryDirectory error:nil],
          [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cachesDirectory error:nil]);
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
