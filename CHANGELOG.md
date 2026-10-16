# LifeClock 版本日志

## v1.0.4 (2026-10-16)

### UI 优化
- **设置页面版本号移至右上角**，与「实时预览」标题水平对齐
- **按钮风格对齐 macOS 系统 UI**：使用 `NSButton.buttonWithTitle:target:action:` 系统标准按钮，主操作按钮绑定 Return 键，取消按钮绑定 ESC 键，按钮右对齐
- **版本号不再出现在屏保列表名称中**：`CFBundleName` 改回 "LifeClock"（无版本后缀），版本号仅在设置页面右上角显示
- **预览框优化**：比例从 16:9 改为 16:10 匹配实际屏幕，内容缩放从 0.5 提升至 0.88，黑边大幅缩小
- **冒号横向居中对齐**：数字间的 `:` 号视觉中心偏下，添加 `translateY(-0.06em)` 修正

### 配置修复
- **「恢复默认」改为临时改动**：点击后只更新 UI 控件，点「确认」才持久化，点「取消」丢弃
- **`WVSSConfig.synchronize` 强制刷盘**：末尾添加 `[self.userDefaults synchronize]`，确保点「确认」后下次屏保启动能读到新值
- **明暗程度默认值从 0.3 改为 0.7**，同步更新滑杆范围（min 从 0.1 改为 0.3，与缩放滑杆一致）

### 工程整理
- **删除旧脚本 `install-from-source.sh`**（已被 `build_saver.sh` + `Build.command` 取代）
- **`index.html` 源文件移至 `WebViewScreenSaver/`** 目录下
- **新增 `Build.command`**：双击即可构建并安装

## v1.0.3 (2026-10-15)

### Bug 修复
- **补上 v1.0.2 的盲点：`self.bounds` 自身被撑成像素尺寸时自检完全静默**。v1.0.2 的 `syncWebViewFrame` 只做 `_webView.frame = self.bounds`，当 `self.bounds` 本身就是错的，`webView.frame == self.bounds` 会被判定为"正常"，watchdog 永不触发；同时 `reInjectConfig` 把这个错误尺寸当作 `screenWidth/screenHeight` 注入前端，`resolveViewport()` 的交叉校验也一并失效，页面按 2880×1800 布局，居中内容正好落在可见区（1440×900）右上角顶点并被裁掉四分之三
- **根因已由统一日志实测坐实：AppKit autoresizing 的加法退化**。宿主先把父视图建成 `0×0`，随后撑到 `1440×900`；此时 `resizeWithOldSuperviewSize:` 拿到的 `oldSize` 为 `0×0`，无法按比例换算，退化为"把全部增量加到子视图"，于是 `1440+1440 = 2880`、`900+900 = 1800`。数值恰好等于像素尺寸只是 scale=2 的巧合，非 Retina 外接屏上同样会翻倍，因此**不能依赖倍率判断**
- **新增 `syncSelfFrame`**：只认一条不变量——屏保视图必须与权威参考尺寸（优先 `superview.bounds`，退回窗口内容区 / 窗口 / 屏幕）等大；不等即纠正自身 size（保留 origin，预览态不动），并置位 `_pendingReinject` 触发配置重注入

### 工程改进
- **诊断日志双写到统一日志（os_log）**：磁盘日志位于屏保沙盒容器 `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Logs/LifeClock/diag.log`，读取需要「完全磁盘访问权限」（`Read` / `cp` / Finder / 用户终端四条路径均被 TCC 拒绝）；改为同时 `os_log`，`log show` 无需任何授权即可取证
- **几何快照增加 `superview=` 与 `ref=` 字段**：可直接看出是宿主给错尺寸还是 autoresizing 算错
- **30 秒几何心跳**：`heartbeat tick=N` 周期落盘，用于区分"异常从会话开始就存在"与"运行中途被改坏"
- **`build_saver.sh` 移出 iCloud 同步目录再签名**：项目位于 `~/Documents` 下，bundle 会带上 `com.apple.fileprovider.fpfs#P`（`xattr -cr` 无法清除），导致 `codesign` 报 `resource fork, Finder information, or similar detritus not allowed`；改为先在 `/tmp` 暂存目录清理并签名，再拷回项目根目录

---

## v1.0.2 (2026-10-15)

### Bug 修复
- **修复屏保偶发"数字跑到右上角并被裁切一大半"**：根因是 `WKWebView` 的 frame 偶发被 AppKit autoresizing 算成屏幕像素尺寸（Retina 下为 points 的 2 倍），非 flipped 坐标系下仅左下象限可见。新增 `syncWebViewFrame`，在 `startAnimation`、`resizeWithOldSuperviewSize:`、`viewDidMoveToWindow` 三处强制纠正 frame
- **修复前端视口无自愈能力**：`ResizeObserver` 改为观察 `documentElement`（原观察的 mirror 元素尺寸由 JS 自己写死，视口变化时不触发，形成自愈死锁）；恢复 `window.resize` / `visualViewport.resize` 监听并合帧节流
- **修复原生注入的 screenWidth/screenHeight 为死代码**：新增 `resolveViewport()`，用 `window.screen` 与原生注入尺寸交叉校验，`innerWidth` 超出参考值 1.5 倍时钳制回参考尺寸
- **修复 `build_saver.sh` 签名被破坏**：原脚本在 `codesign` 之后才覆盖 `index.html` 导致签名失效；改为构建前同步根目录 index.html 到 `WebViewScreenSaver/Resources/`，并新增 `codesign --verify` 校验

### 工程改进
- **frame 自检 watchdog**：每 2 秒校验一次 WebView frame，异常即纠正，避免异常画面持续停留
- **离线诊断日志**：会话开始 / 窗口移动 / resize / frame 纠正等几何事件追加写入 `~/Library/Logs/LifeClock/diag.log`（超 1MB 轮转为 `.1`），屏保退出后仍可复盘

---

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