# AGENTS.md

## 项目概述
`instance_bridge_core` 是 Flutter 插件桥接层（`get_instance_bridge`）的共享核心库，通过 CocoaPods / SPM 被 iOS/macOS 两个 Flutter 插件复用。仓库只有 `darwin/` 共享源码（podspec + `instance_bridge_core/Package.swift` + `Sources/`）、`lib/`（空 Dart 库）和 `pubspec.yaml`（插件声明），**没有 Xcode 工程、测试、Podfile**。

## 构建与发布
- **验证**：`pod lib lint darwin/instance_bridge_core.podspec`；SPM 语法验证：`cd darwin/instance_bridge_core && swift package dump-package`
- **发布流程**：改 `s.version`（同步 `pubspec.yaml` 的 `version`）→ commit → 打同名 git tag（podspec 的 `s.source` 按 tag 拉取）→ push
- 当前版本：0.0.15；历史 tag：0.0.1–0.0.14

## 插件化与共享源码（关键，0.0.13 起采用 sharedDarwinSource）
- 根目录 `pubspec.yaml` 声明 `flutter.plugin`：ios/macos 均为 `pluginClass: InstanceBridgeCorePlugin` + `sharedDarwinSource: true`
- **原因**：`get_instance_bridge` 通过 SPM 依赖本包时，本包必须被 Flutter symlink 到 `.packages/`，其 `Package.swift` 中的 `path: "../FlutterFramework"` 才能解析（非插件的独立 Swift 包无法通过 git 依赖接入 Flutter SPM 构建）
- 共享源码物理位于 `darwin/`（Flutter 官方 `sharedDarwinSource` 机制，工具链 `_darwinPluginDirectoryName` 返回 `darwin/`）
- `darwin/instance_bridge_core/Sources/instance_bridge_core/InstanceBridgeCorePlugin.swift` 是空实现：通道注册由宿主插件 `get_instance_bridge` 完成，本包不注册任何通道
- `lib/instance_bridge_core.dart` 是空 Dart 库（满足 pub 包规范），无 Dart API

## CocoaPods 支持（关键）
- podspec 位于 `darwin/instance_bridge_core.podspec`（`pluginPodspecPath` = `<path>/darwin/instance_bridge_core.podspec`）
- **`source_files` 与 license file 必须物理位于 pod root（`darwin/`）内，不能用符号链接、不能用 `../` 跳出**：CocoaPods 的 `PathList#read_file_system` 用 `Dir.glob('**/*')` 预收集文件，Ruby 的 `**` **不递归进入符号链接目录**；trunk push 单独处理 spec，`'../LICENSE'` 这类跳出 pod root 的相对路径无法解析。踩过的坑：`ios/instance_bridge_core/Sources -> ../../Sources` + `source_files = '../Sources/...'` 导致收集到 0 个源文件，pod target 退化成无源码的 `PBXAggregateTarget`，宿主 `import instance_bridge_core` 失败；`s.license :file => '../LICENSE'` 导致 trunk push 报 "Unable to read the license file"。`darwin/` 下放 LICENSE 物理副本（与根目录保持一致）
- `instance_bridge_core` 是 `get_instance_bridge` 的 pubspec 依赖（Flutter 插件），example 的 Podfile 由 `flutter_install_all_*_pods` 自动安装；**不要**在 Podfile 里手动 `pod 'instance_bridge_core', :git => ...`，否则报 "multiple dependencies with different sources"
- 宿主插件 `get_instance_bridge` 的 podspec 通过 `s.dependency 'instance_bridge_core', '~> 0.0.15'` 约束版本

## SPM 支持（关键）
- 单一清单：`darwin/instance_bridge_core/Package.swift`（同时声明 `.iOS(.v13)` 与 `.macOS(.v10_15)`）。Flutter 工具链对 ios/macos 两个平台都会解析到 `darwin/<name>/Package.swift`
- **Package.swift 必须位于 `darwin/<name>/`**（sharedDarwinSource）或 `ios/<name>/`、`macos/<name>/`：`pluginSwiftPackagePath` 按此硬编码，找不到就不会生成 symlink
- 源码物理位于 `darwin/instance_bridge_core/Sources/`（无符号链接，与 CocoaPods 要求一致）
- Swift/ObjC 拆两个 target：SPM 不允许一个 target 混用两种语言；ObjC 在 `Sources/instance_bridge_core_objc/`（`instance_bridge_core_objc` target），Swift 侧通过 `#if canImport(instance_bridge_core_objc)` 条件 import（见 `ResultMapping.swift`）
- product 双名：`instance_bridge_core`（宿主插件 manifest 引用）+ `instance-bridge-core`（Flutter 生成的 FlutterGeneratedPluginSwiftPackage 按插件名连字符化引用）
- `FlutterFramework` 是 Flutter 构建系统生成的本地包；本包必须作为 Flutter 插件被 symlink 消费（见上）

## 平台条件编译（关键）
Flutter 相关代码必须按此模式导入：
```swift
#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif
```
- Swift 文件用 `os(iOS)/os(macOS)`；头文件 `FlutterErrorExt.h` 用 `TARGET_OS_OSX`
- 部署目标：iOS 13.0 / macOS 10.15（podspec 中需同时设置 `s.ios.deployment_target` 和 `s.osx.deployment_target`，漏掉 macOS 会导致编译失败）

## 架构速览
| 类型 | 职责 |
|------|------|
| `InstancesManager` | 单例 enum，持有 `MixInstances` method channel，按 `typeName_hash` 注册/缓存/销毁实例 |
| `MixCallHandler<T, R>` | 核心抽象，大量 init 变体处理参数解码+结果编码（coc/cic/cov/civ/coe/cie/doc/dic/dov/div/doe/die/vc/vv/ve） |
| `FlutterResponder` | `init(_ hashCode: Int64, _ arguments: Any?)` + `callMethod` 协议 |
| `FlutterRequester` | 原生→Flutter 调用，走 `channel.invokeMethod("method.\(name).\(hashCode).\(method)")` |
| `MixInstance` | = FlutterResponder + FlutterRequester，通过 `[String: AnyMixCallHandler]` 路由方法 |
| `DefaultResponder` | subscript-based 替代方案 |
| `HashInstance` / `ObjInstance` | 可直接继承的基类 |

## 通道协议（wire format）
- 通道名：`MixInstances`
- `instance` — 创建实例，参数 `{typeName, hash, arguments}`
- `destroy` — 销毁实例，参数 `{typeName, hash}`
- `method.<typeName>.<hash>.<methodName>` — 转发到具体实例的 handler（method 名必须恰好 4 段）
- `cleanCaches` — 仅 DEBUG 编译，清空缓存
- **`hash` 必须是 `Int64`**

## AnyEncoder / AnyDecoder（重要）
**不要替换为 JSONEncoder/JSONDecoder！** Flutter method channel 传的是 `NSDictionary/NSArray/NSNumber`（`Any`），不是 Data/JSON。
- `AnyDecoder.decode(_:from:)` 第二个参数是 `Any`
- `AnyEncoder.encode(_:)` 返回 `NSCoding`（实际是 `[String: Any]` / `[Any]`）

## 错误处理
- `FlutterRequestError`：errorDomain `"YYPlatformError"`，code 400/404/405/409
- `toFlutterFailure(_ error)`：NSError → FlutterError，内部调用 `FlutterErrorExt.h/m` 中的 C 函数
- 全局转换器：`yyiSetNSErrorToFlutterErrorHandler(handler)` 可自定义映射

## MainActor 调度模式
所有 handler 路径统一使用此模式，新增代码遵循：
```swift
if #available(iOS 13.0, *), Thread.isMainThread {
    MainActor.assumeIsolated { ... }
} else {
    DispatchQueue.main.async { ... }
}
```

## 其他约定
- 注释语言：**中文**，新代码保持一致
- `FlutterMethodNotImplemented` 在 Swift 中比较需用 `$0 as? NSObject == FlutterMethodNotImplemented`，不能直接 `==`
- 所有 handler 都是 `@MainActor @Sendable`，不要在 handler 内做耗时阻塞操作
