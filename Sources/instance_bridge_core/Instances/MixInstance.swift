//
//  MixViewModel.swift
//
//  Created by crliao on 2023/3/13.
//

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

public protocol MixInstance: FlutterResponder, FlutterRequester {
    
    var callHandler: [String: AnyMixCallHandler] { get }
}

/// 用于实现 响应flutter 调用
public extension MixInstance {
    
    var name: String {
        String(describing: Self.self)
    }
    
    ///
    func callMethod(_ method: String, _ arguments: Any?, result: @escaping (Any) -> Void, error: @escaping (Error) -> Void) {
        if let handler = callHandler[method] {
            handler.callHandler(arguments, result, error)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}
