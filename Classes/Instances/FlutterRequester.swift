//
//  FlutterRequest.swift
//
//  Created by LCR on 2023/9/2.
//

import Foundation

public protocol FlutterRequester {
    var name: String { get }
    var hashCode: Int64 { get }
}

/// 用于调用flutter方法
extension FlutterRequester {
    
    public var name: String {
        String(describing: Self.self)
    }
    
    ///
    private func perform(_ method: String,
                         _ arguments: Any,
                         _ onResult: ((Any?) -> Void)?,
                         _ onError: ((Error) -> Void)?) {
        
        InstancesManager.channel.invokeMethod("method.\(name).\(hashCode).\(method)", arguments: arguments) { result in
            if let error = result as? Error {
                onError?(error)
            } else {
                onResult?(result)
            }
        }
    }
    
    ///
    public func perform(flutter method: String, onResult: ((Any?) -> Void)? = nil,
                        onError: ((Error) -> Void)? = nil) {
        perform(method, 0, onResult, onError)
    }
    
    ///
    public func perform<T: Encodable>(flutter method: String,
                                      arguments: T,
                                      onResult: ((Any?) -> Void)? = nil,
                                      onError: ((Error) -> Void)? = nil) {
        do {
            let data = try AnyEncoder().encode(arguments)
            perform(method, data, onResult, onError)
        } catch {
            onError?(error)
        }
    }
    
    ///
    public func perform(flutter method: String,
                        value: Int,
                        onResult: ((Any?) -> Void)? = nil,
                        onError: ((Error) -> Void)? = nil) {
        perform(method, value, onResult, onError)
    }
    
    ///
    public func perform(flutter method: String,
                        value: Double,
                        onResult: ((Any?) -> Void)? = nil,
                        onError: ((Error) -> Void)? = nil) {
        perform(method, value, onResult, onError)
    }
    
    ///
    public func perform(flutter method: String,
                        value: String,
                        onResult: ((Any?) -> Void)? = nil,
                        onError: ((Error) -> Void)? = nil) {
        perform(method, value, onResult, onError)
    }
    
    
    ///
    public func perform(flutter method: String,
                        value: Bool,
                        onResult: ((Any?) -> Void)? = nil,
                        onError: ((Error) -> Void)? = nil) {
        perform(method, value, onResult, onError)
    }
    
    ///
    public func perform(flutter method: String,
                        arguments: [String: Any],
                        onResult: ((Any?) -> Void)? = nil,
                        onError: ((Error) -> Void)? = nil) {
        perform(method, arguments, onResult, onError)
    }
}
