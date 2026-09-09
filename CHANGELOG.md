## 0.0.15

- Swift 6 并发支持：`HashInstance` 和 `ObjInstance` 添加 `@unchecked Sendable` 标记
- 解决 Swift 6 编译中继承这些基类的 Repository 类在 `@Sendable @MainActor` 闭包内捕获 `self` 的并发错误

## 0.0.14

- 修复 CocoaPods trunk 发布：`darwin/` 下放 LICENSE 物理副本，podspec 的 license file 改为 pod root 内路径（`'../LICENSE'` 在 trunk 单独处理 spec 时无法解析）
- 版本号同步：podspec 与 pubspec 均为 0.0.14

## 0.0.13

- 采用官方 `sharedDarwinSource` 结构：源码物理迁移到 `darwin/instance_bridge_core/Sources/`，消除符号链接
- 修复 CocoaPods 源码收集问题：`Dir.glob('**/*')` 不递归符号链接目录，旧 symlink 结构导致收集到 0 个源文件
- pubspec 的 ios/macos 声明加 `sharedDarwinSource: true`

## 0.0.12

- podspec `source_files` 改为 pod root 内路径，修复 CocoaPods 集成时源文件收集失败

## 0.0.11

- 新增 `ios/`、`macos/` 双平台 podspec，恢复 CocoaPods 双轨支持

## 0.0.10

- 插件化声明：新增 `pubspec.yaml` 的 `flutter.plugin`（pluginClass: `InstanceBridgeCorePlugin`），使本包被 Flutter 工具链识别为插件
- SPM 支持：新增 `ios/instance_bridge_core/Package.swift` 与 `macos/instance_bridge_core/Package.swift`（双平台清单，product 双名）
- Swift/ObjC 拆分：ObjC 辅助代码移至独立 target，Swift 侧通过 `#if canImport` 条件 import

## 0.0.9

- 源码迁移至 `Sources/` 目录（标准 SPM 结构）
- 根目录新增 `Package.swift`（swift-tools-version 5.9）
