# GYBootingProtection
A tool for detecting and repairting continuous launch crash of iOS App

## 说明
### 引入项目

1. 将 `src` 目录下所有文件拖拽到你的 Xcode 项目

2. 在 `AppDelegate+GYBootingProtection.m` 的 `onBeforeBootingProtection` 方法中添加检测前需要执行的代码，比如设置crash上报：

  ```
  - (void)onBeforeBootingProtection {
    [GYBootingProtection setLogger:^(NSString *msg) {
        // setup logger
        NSLog(@"%@", msg);
    }];
    
    [GYBootingProtection setReportBlock:^(NSInteger crashCounts) {
        // setup crash report
    }];
  }
  ```

3. 在 `onBootingProtection` 方法中添加修复逻辑，比如删除文件：

	```
	- (void)onBootingProtection {
		// 检查 JSPatch 更新
		...
		// 删除 Documents Library Caches 目录下所有文件
		[GYBootingProtection deleteAllFilesUnderDocumentsLibraryCaches];
    	...
	}
	```
	
	如需执行异步的修复逻辑，在 `onBootingProtectionWithCompletion:` 方法添加修复逻辑，并在完成修复后调用 completion ：

	```
	- (void)onBootingProtectionWithCompletion:(BoolCompletionBlock)completion {
   		[self onBootingProtection];
    	// 异步修复
   		[self asyncRepairWithCompletion:^(void) {
	    	// 正常启动流程
   			if (completion) completion();
   		}];
	}
	```

### 测试与使用

1. 首先制造连续闪退场景：

  启动后 5 秒内，双击 Home 通过上划手势 kill 掉 App，重复多次。（也可以在代码里人为制造crash）

2. 当连续闪退超过 5 次时，会提示用户修复：

  ![img](./img/GYBootingProtectionTips.png)

3. 用户轻触修复，App 重置初始状态，连续闪退问题解决：

  ![img](./img/GYBootingProtectionAfter.png)

