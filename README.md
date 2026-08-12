# instance_bridge_core

Shared core code (Swift + Objective-C) for Flutter plugin bridge.  
Designed to be reused by both iOS and macOS Flutter plugins.

## Features

- Shared Swift/Objective-C logic
- Used by `get_instance_bridge`
- Supports both CocoaPods and Swift Package Manager

## Installation

### CocoaPods

In your plugin `.podspec`:

```ruby
s.dependency 'instance_bridge_core'
```

### Swift Package Manager

In your plugin `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yysy-iot/instance_bridge_core.git", from: "0.0.8"),
    .package(name: "FlutterFramework", path: "../FlutterFramework")
],
targets: [
    .target(
        name: "your_plugin",
        dependencies: [
            .product(name: "instance_bridge_core", package: "instance_bridge_core"),
            .product(name: "FlutterFramework", package: "FlutterFramework")
        ]
    )
]
```

> **注意**：`instance_bridge_core` 依赖 `FlutterFramework`（Flutter 构建系统生成的本地包）。
> 通过远程 Git 消费时，需由消费者在 Xcode 中以本地包覆盖（Local Package Override）提供该依赖。