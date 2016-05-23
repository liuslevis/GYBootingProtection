//
//  GYBootingProtection.m
//  GYMonitor
//
//  Created by jasenhuang on 15/12/22.
//

#import "GYBootingProtection.h"
#import <QuartzCore/QuartzCore.h>

void (^Logger)(NSString *log);

static NSString *const kStartupCrashForTest = @"StartupCrashForTest"; // 尝试制造启动 crash 彩蛋
static NSString *const kContinuousCrashOnLaunchCounterKey = @"ContinuousCrashOnLaunchCounter";
static NSString *const kContinuousCrashFixingKey = @"ContinuousCrashFixing"; // 是否正在修复
static NSInteger const kContinuousCrashOnLaunchNeedToReport = 5;
static NSInteger const kContinuousCrashOnLaunchNeedToFix = 5;
static CFTimeInterval const kCrashOnLaunchTimeIntervalThreshold = 5.0;
static CFTimeInterval g_startTick; // 记录启动时刻

@implementation GYBootingProtection

+ (BOOL)launchContinuousCrashProtectWithReportBlock:(ReportBlock)reportBlock
                                        repairBlock:(RepairBlock)repairBlock
                                         completion:(BoolCompletionBlock)completion
{
    NSAssert(repairBlock, @"repairBlock is nil!");
    if (Logger) Logger(@"GYBootingProtection: Launch continuous crash report");
    [self setIsFixing:NO];
    
    NSInteger launchCrashes = [self crashCount];
    // 上报
    if (launchCrashes >= kContinuousCrashOnLaunchNeedToReport) {
        if (Logger) Logger([NSString stringWithFormat:@"GYBootingProtection: App has continuously crashed for %@ times. Now synchronize uploading crash report and begin fixing procedure.", @(launchCrashes)]);
        if (reportBlock) reportBlock(launchCrashes);
    }
    
    [self setCrashCount:[self crashCount]+1];


    // 记录启动时刻，用于计算启动连续 crash
    g_startTick = CACurrentMediaTime();
    // 重置启动 crash 计数
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kCrashOnLaunchTimeIntervalThreshold * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        // APP活过了阈值时间，重置崩溃计数
        if (Logger) Logger([NSString stringWithFormat:@"GYBootingProtection: long live the app ( more than %@ seconds ), now reset crash counts", @(kCrashOnLaunchTimeIntervalThreshold)]);
        [self setCrashCount:0];
    });
    
    
    // 修复
    if (launchCrashes >= kContinuousCrashOnLaunchNeedToFix) {
        if (Logger) Logger(@"need to repair");
        [self setIsFixing:YES];
        if (repairBlock) {
            repairBlock(^BOOL(){
                [self setCrashCount:0];
                [self setIsFixing:NO];
                if (completion) {
                    if (Logger) Logger(@"repairBlock will execute completion block");
                    return completion();
                } else {
                    if (Logger) Logger(@"repairBlock will not execute completion block (nil)");
                    return NO;
                }
            });
        }
    } else {
        // 正常流程，无需修复
        if (Logger) Logger(@"need no repair");
        if (completion) {
            if (Logger) Logger(@"will execute completion block");
            return completion();
        }
    }
    return NO;
}

+ (void)setIsFixing:(BOOL)isFixingCrash
{
    if (Logger) Logger([NSString stringWithFormat:@"setisFixingCrash:{%@}",@(isFixingCrash)]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isFixingCrash forKey:kContinuousCrashFixingKey];
    [defaults synchronize];
}

+ (void)setCrashCount:(NSInteger)count
{
    if (Logger) Logger([NSString stringWithFormat:@"setCrashCount:%@", @(count)]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:count forKey:kContinuousCrashOnLaunchCounterKey];
    [defaults synchronize];
}

+ (BOOL)isFixingCrash
{
    BOOL isFixingCrash = [[NSUserDefaults standardUserDefaults] boolForKey:kContinuousCrashFixingKey];
    if (Logger) Logger([NSString stringWithFormat:@"isFixingCrash:%@", @(isFixingCrash)]);
    return isFixingCrash;
}

+ (NSInteger)crashCount
{
    NSInteger crashCount = [[NSUserDefaults standardUserDefaults] integerForKey:kContinuousCrashOnLaunchCounterKey];
    if (Logger) Logger([NSString stringWithFormat:@"crashCount:%@", @(crashCount)]);
    return crashCount;
}

+ (void)setLogger:(void (^)(NSString *))logger
{
    Logger = [logger copy];
}

+ (void)setStartupCrashForTest:(BOOL)isOn
{
    if (Logger) Logger([NSString stringWithFormat:@"setStartupCrashForTest:%@", @(isOn)]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:isOn forKey:kStartupCrashForTest];
    [defaults synchronize];
}

+ (BOOL)startupCrashForTest
{
    if ([GYBootingProtection crashCount] >= kContinuousCrashOnLaunchNeedToFix) {
        return NO;
    }
    BOOL ret = [[NSUserDefaults standardUserDefaults] boolForKey:kStartupCrashForTest];
    if (Logger) Logger([NSString stringWithFormat:@"startupCrashForTest:%@", @(ret)]);
    return ret;
}

@end
