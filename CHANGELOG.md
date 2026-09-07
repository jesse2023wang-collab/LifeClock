# LifeClock 版本日志

## v1.0.1 (2026-09-07)

### 功能更新
- **亮度控制修复**：亮度设置现在正确控制所有文字和符号（包括翻页数字），不再只控制英文文本
- **DOM 性能优化**：使用 Map 缓存 flip-card 子元素引用、ResizeObserver 替代轮询、动画常量提取
- **代码质量提升**：全部 `var` 替换为 `const`/`let`、删除死代码、删除冗余赋值、添加输入校验
- **构建脚本改进**：`build_saver.sh` 支持通用二进制（arm64 + x86_64），自动处理扩展属性清理和签名

### Bug 修复
- **修复 `decisionHandler` 双重调用崩溃**：`decidePolicyForNavigationAction` 中缺失 `return;` 导致同一 handler 被调用两次
- **修复 `NSSlider.integerValue = NO` 错误用法**：`integerValue` 是 getter，赋值 `NO` 实际将滑块值设为 0；改为 `allowsTickMarkValuesOnly = NO`
- **修复出生日期选择器文字颜色**：白字配白底不可见，改为黑字白底
- **修复 `NSKeyedArchiver`/`NSKeyedUnarchiver` 静默失败**：传入 `&error` 并检查返回值
- **修复构建 CodeSign 失败**：`com.apple.provenance` 扩展属性导致签名拒绝，构建脚本自动清理再手动签名

### Objective-C 代码改进
- **私有 API 防护**：`wvss_setWindowOcclusionDetectionEnabled:` 添加 `respondsToSelector`
- **`defaultBirthDate()` 缓存**：`dispatch_once` 缓存默认日期对象
- **删除已弃用的 `synchronize`**：移除 `[NSUserDefaults synchronize]`
- **删除未使用的 `bundleHTML` 方法**

### 工程改进
- **`install-from-source.sh` 重写**：修复构建上游项目而非本地 LifeClock 的问题
- **`build_saver.sh` 增强**：`set -euo pipefail`、`ARCHS="arm64 x86_64"`、扩展属性清理、手动签名
- **`index.html` 三副本同步**：根目录为主源文件，构建脚本自动同步

---

## v1.0.0 (2026-07-07)

### Bug 修复
- **修复出生日期配置不生效的问题**：配置现在通过 `WKNavigationDelegate` 的 `didFinishNavigation` 回调注入，确保页面完全加载后再调用 `window.reconfigureScreenSaver()`，避免配置被默认值覆盖
- **修复 `stopAnimation` 条件写反**：非预览模式下现在会正确清理 webview 和 timer
- **修复 `WVSSConfig.m` 默认值读取逻辑**：`scale`/`brightness` 使用显式 `objectForKey:` 判断，避免 `floatForKey` 返回 `0.0` 时的误判
- **修复 `_Nonnull` 与 `nil` 矛盾**：移除 `static NSDate * _Nonnull const kDefaultBirthDate = nil` 的不安全声明
- **修复 `NSDateFormatter` 格式稳定性**：添加 `en_US_POSIX` locale 和 `localTimeZone`，避免系统 locale 影响日期解析

### 前端优化
- **差量更新 DOM**：时钟数字块在 HTML 中预创建，`tick()` 只更新 `textContent`，不再每秒销毁重建 7 个 DOM 节点
- **移除无意义的三元表达式**：`pad(t.hr, config.timeFormat === '01-12' ? 2 : 2)` 简化为固定值

### Objective-C 代码改进
- **替换废弃 API**：`NSKeyedArchiver archivedDataWithRootObject:` 和 `NSKeyedUnarchiver unarchiveObjectWithData:` 升级为支持 `requiringSecureCoding` 的版本
- **清理未使用代码**：删除 `loadFromStart` 中已失效的 URL 查询参数拼接逻辑
- **配置面板增强**：出生日期选择器增加时分秒选择（`NSDatePickerElementFlagHourMinuteSecond`）和本地时区设置

### 工程改进
- **新增一键编译脚本**：`test.sh` 支持用 `clang` 直接编译（无需完整 Xcode）
- **新增双击安装脚本**：`Install.command` 双击即可在 Terminal 中执行编译安装
- **版本号更新**：`CFBundleShortVersionString` / `CFBundleVersion` 更新为 `1.0.0`
- **显示名称带版本后缀**：`CFBundleName` 改为 `LifeClock v1.0.0`，系统设置中可直接看到版本
- **目录结构优化**：`README.md` 和 `index.html` 整理到 `LifeClock_MAC/` 目录下

---

## 历史版本

### v2.4 (原始版本)
- 基于 WebViewScreenSaver 的初始版本
- 支持 macOS 屏保，使用 WKWebView 加载 HTML 前端
- 基础配置：时间格式、出生日期、缩放、亮度、背景显示