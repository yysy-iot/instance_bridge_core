// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "instance_bridge_core",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "instance_bridge_core", targets: ["instance_bridge_core"])
    ],
    dependencies: [
        // FlutterFramework 是 Flutter 构建系统在 ios/FlutterFramework/ 生成的本地包。
        // 通过远程 Git 消费时，需由消费者在 Xcode 中以本地包覆盖（Local Package Override）提供。
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "instance_bridge_core",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/instance_bridge_core",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ]
        )
    ]
)
