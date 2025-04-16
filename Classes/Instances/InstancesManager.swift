//
//  instancesManager.swift
//
//  Created by crliao on 2023/3/12.
//

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

public enum InstancesManager {
    
    private static var builderMap = [String: (Int64, Any?) -> FlutterResponder]()
    private static var cachesMap = [String: FlutterResponder]()
    
    private static func key(_ typeName: String, _ hash: Int64) -> String { typeName + "_\(hash)" }
    
    private static var _channel: FlutterMethodChannel!
    static var channel: FlutterMethodChannel { _channel }
    
    // MARK: -
    
    static func initChannel(_ messenger: FlutterBinaryMessenger) {
        _channel = .init(name: "MixInstances", binaryMessenger: messenger)
        _channel.setMethodCallHandler(callHandler)
    }
    
    public static func register(type: FlutterResponder.Type) {
        let typeName = String(describing: type)
        register(typeName, with: type)
    }
    
    public static func register(_ typeName: String, with
                                type: FlutterResponder.Type) {
        register(typeName, with: type.init)
    }
    
    public static func register(_ typeName: String, with
                                builder: @escaping (Int64) -> FlutterResponder) {
        builderMap[typeName] = { hash, _ in
            builder(hash)
        }
    }
    
    public static func register(_ typeName: String, with
                                builder: @escaping (Int64, Any) -> FlutterResponder) {
        builderMap[typeName] = builder
    }
    
    ///
    private static func find(_ typeName: String, hash: Int64) -> FlutterResponder? {
        let key = self.key(typeName, hash)
        return cachesMap[key]
    }
    
    ///
    private static func create(_ typeName: String, hash: Int64, arguments: Any?) -> FlutterResponder? {
        let key = self.key(typeName, hash)
        if let instance = cachesMap[key] { return instance }
        guard let instance = builderMap[typeName]?(hash, arguments) else { return nil }
        cachesMap[key] = instance
        return instance
    }
    
    ///
    @discardableResult
    private static func destroy(_ typeName: String, hash: Int64) -> FlutterResponder? {
        let key = self.key(typeName, hash)
        return cachesMap.removeValue(forKey: key)
    }
    
    // MARK: -
    
    private static func callHandler(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "instance":
            instance(call.arguments, result)
        case "destroy":
            destroy(call.arguments, result)
#if DEBUG
        case "cleanCaches":
            cachesMap.removeAll()
            result(0)
#endif
        default:
            if call.method.hasPrefix("method") {
                method(call, result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

    }
    
    private static func method(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let components = call.method.components(separatedBy: ".")
        guard components.count == 4, let hash = Int64(components[2]) else {
            result(FlutterMethodNotImplemented)
            return
        }
        let typeName = components[1]
        //
        guard let instance = find(typeName, hash: hash) else {
            result(toFlutterFailure(FlutterRequestError.invalidObject))
            return
        }
        instance.callMethod(components[3], call.arguments) {
            if $0 as? NSObject == FlutterMethodNotImplemented {
                result(FlutterMethodNotImplemented)
            } else {
                result($0)
            }
        } error: {
            result(toFlutterFailure($0))
        }
    }
    
    private static func instance(_ arguments: Any?, _ result: @escaping FlutterResult) {
        guard let arguments = arguments as? [String: Any],
              let typeName = arguments["typeName"] as? String,
              !typeName.isEmpty,
              let hash = arguments["hash"] as? Int64,
              create(typeName, hash: hash, arguments: arguments["arguments"]) != nil else {
            result(FlutterMethodNotImplemented)
            return
        }
        voidSuccess(result)()
    }
    
    private static func destroy(_ arguments: Any?, _ result: @escaping FlutterResult) {
        guard let arguments = arguments as? [String: Any],
              let typeName = arguments["typeName"] as? String,
              !typeName.isEmpty,
              let hash = arguments["hash"] as? Int64 else {
            result(FlutterMethodNotImplemented)
            return
        }
        destroy(typeName, hash: hash)
        voidSuccess(result)()
    }
}
