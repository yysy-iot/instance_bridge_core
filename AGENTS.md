# AGENTS.md

## 项目概述
`instance_bridge_core` 是 Flutter 插件桥接层（`get_instance_bridge`）的共享核心库，通过 CocoaPods 被 iOS/macOS 两个 Flutter 插件复用。仓库只有 `Sources/instance_bridge_core/` 源码、podspec 和 `Package.swift`（SPM），**没有 Xcode 工程、测试、Podfile**。

## 构建与发布
- **验证**：`pod lib lint instance_bridge_core.podspec`；SPM 语法验证：`swift package dump-package`
- **发布流程**：改 `s.version` → commit → 打同名 git tag（podspec 的 `s.source` 按 tag 拉取）→ push
- 当前版本：0.0.8；历史 tag：0.0.1–0.0.8

## SPM 支持（关键）
- 根目录 `Package.swift`：swift-tools-version 5.9，依赖 `FlutterFramework`（`path: "../FlutterFramework"`）
- 源码结构：`Sources/instance_bridge_core/`，公开 ObjC 头文件在 `include/`（`publicHeadersPath`）
- `FlutterFramework` 是 Flutter 构建系统生成的本地包；远程 Git 消费时需消费者在 Xcode 中以本地包覆盖提供
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
