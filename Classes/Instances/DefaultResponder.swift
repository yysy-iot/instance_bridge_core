//
//  DefaultResponder.swift
//
//  Created by LCR on 2023/9/2.
//

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif


public protocol DefaultResponder: FlutterResponder {
    
    subscript(method: String) -> AnyMixCallHandler? { get }
}

/// 用于实现 响应flutter 调用
public extension DefaultResponder {
    
    ///
    func callMethod(_ method: String, _ arguments: Any?, result: @escaping (Any) -> Void, error: @escaping (Error) -> Void) {
        
        if let handler = self[method] {
            handler.callHandler(arguments, result, error)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

}
