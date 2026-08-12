//
//  InstanceBridgeCorePlugin.swift
//
//  Created by crliao on 2026/8/12.
//

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

/// 空实现插件类。
///
/// `instance_bridge_core` 是共享原生库而非独立插件：实例桥接的通道注册由宿主插件
/// （`get_instance_bridge`）完成，这里仅提供 pluginClass 以满足 Flutter 将其作为
/// 插件依赖（从而在 SPM 构建中获得 FlutterFramework symlink）的要求。
public class InstanceBridgeCorePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // 无需注册任何通道，通道注册由宿主插件 get_instance_bridge 负责。
    }
}
