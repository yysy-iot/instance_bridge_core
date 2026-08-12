// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "instance_bridge_core",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // 两个 product 指向同一 target：
        // - instance_bridge_core：宿主插件 get_instance_bridge 的 SPM manifest 中引用
        // - instance-bridge-core：Flutter 生成的 FlutterGeneratedPluginSwiftPackage 按插件名连字符化后引用
        .library(name: "instance_bridge_core", targets: ["instance_bridge_core"]),
        .library(name: "instance-bridge-core", targets: ["instance_bridge_core"])
    ],
    dependencies: [
        // FlutterFramework 是 Flutter 构建系统生成的本地包。本包必须作为 Flutter 插件被
        // symlink 到 .packages/（见根目录 pubspec.yaml 的 flutter.plugin 声明），
        // 此相对路径才能解析到 .packages/FlutterFramework。
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        // ObjC 辅助代码（FlutterErrorExt）。SPM 规定一个 target 内不能混用 Swift 与 C 系语言，
        // 故单独成 target，Swift 侧通过 canImport 条件 import。
        .target(
            name: "instance_bridge_core_objc",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/instance_bridge_core_objc",
            publicHeadersPath: "include"
        ),
        // Swift 主实现。Sources 是指向根目录共享源码的 symlink（iOS/macOS 共用一份源码，条件编译）。
        .target(
            name: "instance_bridge_core",
            dependencies: [
                .target(name: "instance_bridge_core_objc"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
