//
//  ResultMapping.swift
//
//  Created by LCR on 2023/4/21.
//

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

// SPM 下 ObjC 辅助代码（FlutterErrorExt）编译为独立模块 instance_bridge_core_objc，
// Swift target 需要显式 import；CocoaPods 下 Swift/ObjC 同属一个 pod target，
// 通过 -import-underlying-module 自动可见，无需（也无法）import 该模块。
#if canImport(instance_bridge_core_objc)
import instance_bridge_core_objc
#endif

public func toFlutterFailure(_ error: Error) -> FlutterError {
    let error = error as NSError
    return yyiNSErrorToFlutterError(error)
}


public func voidSuccess(_ success: @escaping (Any) -> Void) -> () -> Void {
    {
        success(0)
    }
}
