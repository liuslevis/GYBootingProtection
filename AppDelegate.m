#import "UIAlertView+Blocks.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    /* ------- 启动连续闪退保护 ------- */
    [GYBootingProtection setLogger:^(NSString *msg) {
        // 设置 Logger
        GYLOG(Log_BootingProtection, @"%@", msg);
    }];
    FixBlock fixBlock = ^void(BoolCompletionBlock completion) {
        // 弹 Toast 提示用户修复
        // 	用户选 OK，进入修复流程
        //	用户选 NO，正常启动 
        [self showAlertForFixContinuousCrashOnCompletion:completion];
    };
    ReportBlock reportBlock = ^void(NSInteger crashCounts) {
        // 统计上报逻辑
        [[CrashReporter sharedInstance] checkAndUpload];
    };
    BoolCompletionBlock completion = ^BOOL() {
        // 正常启动逻辑
        return [self startWereadApplication:application withLaunchingOptions:launchOptions];
    };
    return [GYBootingProtection launchContinuousCrashProtectWithReportBlock:reportBlock fixBlock:fixBlock completion:completion];
}

- (BOOL)startWereadApplication:(UIApplication *)application withLaunchingOptions:(NSDictionary *)launchOptions {
	// TODO
	// 原位于 didFinishLauching 的 App 启动逻辑
	...
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

- (void)tryToFixContinuousCrash:(void(^)(void))completion
{
    // 已登录先拉取 JSPatch，在执行本地修复逻辑
    [[WRPreferenceManager sharedInstance] runJSPatch:[GYUICallback callbackWithSuccess:^(id data) {
        [self tryToFixWithLocalLogic];
        if (completion) completion();
    } withError:^(NSError *error) {
        [self tryToFixWithLocalLogic];
        if (completion) completion();
    }]];
}

- (void)tryToFixWithLocalLogic {
    // 删除Document Library Caches 目录下的所有文件
    [WRStorage recoverFromContinuousCrash];
    
    // Fix 完成后清除登录状态
    [[WRLoginManager shareInstance] logout];
}
