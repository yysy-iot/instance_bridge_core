# AGENTS.md

## 项目概述
`instance_bridge_core` 是 Flutter 插件桥接层（`get_instance_bridge`）的共享核心库，通过 CocoaPods 被 iOS/macOS 两个 Flutter 插件复用。仓库只有 `Sources/instance_bridge_core/` 源码、podspec、`Package.swift`（SPM）和 `pubspec.yaml`（插件声明），**没有 Xcode 工程、测试、Podfile**。

## 构建与发布
- **验证**：`pod lib lint instance_bridge_core.podspec`；SPM 语法验证：`swift package dump-package`
- **发布流程**：改 `s.version`（同步 `pubspec.yaml` 的 `version`）→ commit → 打同名 git tag（podspec 的 `s.source` 按 tag 拉取）→ push
- 当前版本：0.0.10；历史 tag：0.0.1–0.0.9

## 插件化声明（关键，0.0.10 起）
- 根目录 `pubspec.yaml` 声明 `flutter.plugin`（ios/macos `pluginClass: InstanceBridgeCorePlugin`），使本包被 Flutter 工具链识别为插件
- **原因**：`get_instance_bridge` 通过 SPM 依赖本包时，本包必须被 Flutter symlink 到 `.packages/`，其 `Package.swift` 中的 `path: "../FlutterFramework"` 才能解析（非插件的独立 Swift 包无法通过 git 依赖接入 Flutter SPM 构建）
- `Sources/instance_bridge_core/InstanceBridgeCorePlugin.swift` 是空实现：通道注册由宿主插件 `get_instance_bridge` 完成，本包不注册任何通道
- `lib/instance_bridge_core.dart` 是空 Dart 库（满足 pub 包规范），无 Dart API

## SPM 支持（关键）
- 平台清单：`ios/instance_bridge_core/Package.swift`（iOS 13.0）、`macos/instance_bridge_core/Package.swift`（macOS 10.15），均依赖 `FlutterFramework`（`path: "../FlutterFramework"`）
- **Package.swift 必须位于 `ios/<name>/`、`macos/<name>/`**：Flutter 工具链 `pluginSwiftPackagePath` 硬编码该结构，找不到就不会生成 symlink
- 共享源码用 symlink：`ios/instance_bridge_core/Sources` → `../../Sources`（ios/macos 共用一份源码，条件编译）
- Swift/ObjC 拆两个 target：SPM 不允许一个 target 混用两种语言；ObjC 在 `Sources/instance_bridge_core_objc/`（`instance_bridge_core_objc` target），Swift 侧通过 `#if canImport(instance_bridge_core_objc)` 条件 import（见 `ResultMapping.swift`）
- product 双名：`instance_bridge_core`（宿主插件 manifest 引用）+ `instance-bridge-core`（Flutter 生成的 FlutterGeneratedPluginSwiftPackage 按插件名连字符化引用）
- 根目录 `Package.swift`：独立包清单，保留用于非插件场景的 SPM 消费
- `FlutterFramework` 是 Flutter 构建系统生成的本地包；本包必须作为 Flutter 插件被 symlink 消费（见上）
- podspec 的 `source_files`/`public_header_files` 与 SPM 目录保持一致

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
