//
//  GYBootingProtection.h
//  GYMonitor
//
//  Created by jasenhuang on 15/12/22.
//

#import <Foundation/Foundation.h>



typedef BOOL (^BoolCompletionBlock)(void);
typedef void (^RepairBlock)(BoolCompletionBlock);
typedef void (^ReportBlock)(NSInteger crashCounts);

/**
 * 启动连续 crash 保护。
 * 启动后kCrashOnLaunchTimeIntervalThreshold秒内crash，反复超过kContinuousCrashOnLaunchNeedToReport次则上报日志，超过kContinuousCrashOnLaunchNeedToFix则启动修复程序
 */
@interface GYBootingProtection : NSObject

/**
 * 启动连续 crash 保护方法。
 * 前置条件：在 App 启动时注册 crash 处理函数，在 crash 时调用[GYBootingProtection addCrashCountIfNeeded]。
 * 启动后kCrashOnLaunchTimeIntervalThreshold秒内crash，反复超过kContinuousCrashOnLaunchNeedToReport次则上报日志，超过kContinuousCrashOnLaunchNeedToFix则启动修复程序；当所有操作完成后，执行 completion。在 kCrashOnLaunchTimeIntervalThreshold 秒后若没有 crash 将 kContinuousCrashOnLaunchCounterKey 计数置零。
 * @param reportBlock 上报逻辑，
 * @param fixBlock    修复逻辑，完成后执行 [self setCrashCount:0];[self setIsFixing:NO];completion();
 * @param completion  完成逻辑，无论是否修复，都会执行completion一次
 * @return (BOOL)completion 的返回值，当不需要修复且 completion 有定义时；
 *         NO 在需要修复时或者其他情况
 */
+ (BOOL)launchContinuousCrashProtect;
// 启动连续 crash 计数
+ (void)setCrashCount:(NSInteger)count;
+ (NSInteger)crashCount;
// 是否正在修复
+ (BOOL)isFixingCrash;
// 设置日志逻辑
+ (void)setLogger:(void (^)(NSString *))logger;
// 设置上报逻辑，参数 crashCounts 为启动连续 crash 次数
+ (void)setReportBlock:(ReportBlock)reportBlock;
// 设置修复逻辑
+ (void)setRepairBlock:(RepairBlock)repairtBlock;
+ (void)setBoolCompletionBlock:(BoolCompletionBlock)boolCompletionBlock;
// 测试彩蛋开关：是否制造启动 crash
+ (void)setStartupCrashForTest:(BOOL)isOn;
// 是否显示测试彩蛋（需要修复时不显示）
+ (BOOL)startupCrashForTest;
// 删除Document Library Caches所有文件
+ (void)deleteAllFilesUnderDocumentsLibraryCaches;
@end
