//
//  MixCallHandler.swift
//
//  Created by LCR on 2023/3/16.
//

import Foundation
//import Flutter

public protocol AnyMixCallHandler {
    
    func callHandler(_ arguments: Any?, _ success: @escaping (Any) -> Void, _ failure: @escaping (Error) -> Void)
}

///
public typealias CastFrom<T> = (Any?) throws -> T?
///
typealias AnyHandler<T> = (T?, @escaping (Any) -> Void, @escaping (Error) -> Void) -> Void
///
public typealias COOHandler<T, R> = (T?, @escaping (R?) -> Void, @escaping (Error) -> Void) -> Void
///
public typealias CIOHandler<T, R> = (T, @escaping (R?) -> Void, @escaping (Error) -> Void) -> Void
///
public typealias COVHandler<T> = (T?, @escaping () -> Void, @escaping (Error) -> Void) -> Void
///
public typealias CIVHandler<T> = (T, @escaping () -> Void, @escaping (Error) -> Void) -> Void
///
public typealias VOHandler<R> = (@escaping (R?) -> Void, @escaping (Error) -> Void) -> Void
///
public typealias VVHandler = (@escaping () -> Void, @escaping (Error) -> Void) -> Void

public struct MixCallHandler<T, R>: AnyMixCallHandler {
    
    public typealias CastFromT = CastFrom<T>
    private let castFrom: CastFromT
    private let handler: AnyHandler<T>
    
    // MARK: Cast T
    
    /// 入参(可选)强转 出参强转
    public init(coc handler: @escaping COOHandler<T, R>) {
        self.castFrom = optAnyCastFrom()
        self.handler = handler
    }
    
    /// 入参强转 出参强转
    public init(cic handler: @escaping CIOHandler<T, R>) {
        self.castFrom = optAnyCastFrom()
        self.handler = argInstanceHandler(handler)
    }
    
    /// 入参(可选)强转 出参Void
    public init(cov handler: @escaping COVHandler<T>) where R == Void {
        self.castFrom = optAnyCastFrom()
        self.handler = argOptHandler(handler)
    }
    
    /// 入参强转 出参Void
    public init(civ handler: @escaping CIVHandler<T>) where R == Void {
        self.castFrom = optAnyCastFrom()
        self.handler = argInstanceHandler(handler)
    }
    
    /// 入参(可选)强转 出参编码
    public init(coe handler: @escaping COOHandler<T, R>) where R: Encodable {
        self.castFrom = optAnyCastFrom()
        self.handler = argOptHandler(handler)
    }
    
    /// 入参强转 出参编码
    public init(cie handler: @escaping CIOHandler<T, R>) where R: Encodable {
        self.castFrom = optAnyCastFrom()
        self.handler = argInstanceHandler(handler)
    }
    
    // MARK: Decodable T
    
    /// 入参(可选)编码 出参强转
    public init(doc handler: @escaping COOHandler<T, R>) where T: Decodable {
        self.castFrom = optDecodableCastFrom()
        self.handler = handler
    }
    
    /// 入参编码 出参强转
    public init(dic handler: @escaping CIOHandler<T, R>) where T: Decodable {
        self.castFrom = optDecodableCastFrom()
        self.handler = argInstanceHandler(handler)
    }
    
    /// 入参(可选)强转 出参Void
    public init(dov handler: @escaping COVHandler<T>) where T: Decodable, R == Void {
        self.castFrom = optDecodableCastFrom()
        self.handler = argOptHandler(handler)
    }
    
    /// 入参强转 出参Void
    public init(div handler: @escaping CIVHandler<T>) where T: Decodable, R == Void {
        self.castFrom = optDecodableCastFrom()
        self.handler = argInstanceHandler(handler)
    }
    
    /// 入参(可选)强转 出参编码
    public init(doe handler: @escaping COOHandler<T, R>) where R: Encodable, T: Decodable {
        self.castFrom = optDecodableCastFrom()
        self.handler = argOptHandler(handler)
    }
    
    /// 入参强转 出参编码
    public init(die handler: @escaping CIOHandler<T, R>) where R: Encodable, T: Decodable {
        self.castFrom = optDecodableCastFrom()
        self.handler = argInstanceHandler(handler)
    }
    
    // MARK: Void T
    
    /// 入参Void 出参强转
    public init(vc handler: @escaping VOHandler<R>) where T == Void {
        self.castFrom = { _ in () }
        self.handler = {
            handler($1, $2)
        }
    }
    
    /// 入参Void 出参Void
    public init(vv handler: @escaping VVHandler) where T == Void, R == Void {
        self.castFrom = { _ in () }
        self.handler =   {
            handler(voidSuccess($1), $2)
        }
    }
    
    /// 入参Void 出参编码
    public init(ve handler: @escaping VOHandler<R>) where R: Encodable, T == Void {
        self.castFrom = { _ in () }
        self.handler = {
            handler(encodeResult($1, $2), $2)
        }
    }
    
    // MARK: Custom T
    
    /// 入参(可选)自定义 出参Void
    public init(_ castFrom: @escaping CastFromT, ov handler: @escaping COVHandler<T>) where R == Void {
        self.castFrom = castFrom
        self.handler = argOptHandler(handler)
    }
    
    /// 入参自定义 出参Void
    public init(_ castFrom: @escaping CastFromT, iv handler: @escaping CIVHandler<T>) where R == Void {
        self.castFrom = castFrom
        self.handler = argInstanceHandler(handler)
    }
    
    /// 入参(可选)自定义 出参强转
    public init(_ castFrom: @escaping CastFromT, oc handler: @escaping COOHandler<T, R>) {
        self.castFrom = castFrom
        self.handler = handler
    }
    
    /// 入参自定义 出参强转
    public init(_ castFrom: @escaping CastFromT, ic handler: @escaping CIOHandler<T, R>) {
        self.castFrom = castFrom
        self.handler = argInstanceHandler(handler)
    }
    
    /// 入参(可选)自定义 出参编码
    public init(_ castFrom: @escaping CastFromT, oe handler: @escaping COOHandler<T, R>) where R: Encodable {
        self.castFrom = castFrom
        self.handler = argOptHandler(handler)
    }
    
    /// 入参自定义 出参编码
    public init(_ castFrom: @escaping CastFromT, ie handler: @escaping CIOHandler<T, R>) where R: Encodable {
        self.castFrom = castFrom
        self.handler = argInstanceHandler(handler)
    }
    
    
    // MARK: - AnyMixCallHandler
    
    
    public func callHandler(_ arguments: Any?,
                            _ success: @escaping (Any) -> Void,
                            _ failure: @escaping (Error) -> Void) {
        do {
            let arguments = try castFrom(arguments)
            handler(arguments, success, failure)
        } catch {
            failure(error)
        }
    }
}

///
private func encodeResult<R: Encodable>(_ onResult: @escaping (Any?) -> Void,
                                        _ onError: @escaping (Error) -> Void) -> (R?) -> Void {
    {
        guard let value = $0 else {
            onResult($0)
            return
        }
        do {
            let obj = try AnyEncoder().encode(value)
            onResult(obj)
            
        } catch {
            onError(error)
        }
    }
}

///
private func optAnyCastFrom<T>() -> CastFrom<T> {
    {
        if $0 == nil { return nil }
        if $0 is T { return $0 as? T }
        throw FlutterRequestError.invalidArgument
    }
}

///
private func optDecodableCastFrom<T: Decodable>() -> CastFrom<T> {
    {
        guard let value = $0 else { return nil }
        if value is T { return value as? T }
        return try AnyDecoder().decode(T.self, from: value)
    }
}

///
private func argInstanceHandler<T, R>(_ handler: @escaping CIOHandler<T, R>) -> AnyHandler<T> {
    {
        guard let value = $0 else {
            $1(FlutterMethodNotImplemented)
            return
        }
        handler(value, $1, $2)
    }
}

///
private func argInstanceHandler<T, R: Encodable>(_ handler: @escaping CIOHandler<T, R>) -> AnyHandler<T> {
    {
        guard let value = $0 else {
            $1(FlutterMethodNotImplemented)
            return
        }
        handler(value, encodeResult($1, $2), $2)
    }
}

///
private func argInstanceHandler<T>(_ handler: @escaping CIVHandler<T>) -> AnyHandler<T> {
    {
        guard let value = $0 else {
            $1(FlutterMethodNotImplemented)
            return
        }
        handler(value, voidSuccess($1), $2)
    }
}

///
private func argOptHandler<T, R: Encodable>(_ handler: @escaping COOHandler<T, R>) -> AnyHandler<T> {
    {
        handler($0, encodeResult($1, $2), $2)
    }
}

///
private func argOptHandler<T>(_ handler: @escaping COVHandler<T>) -> AnyHandler<T> {
    {
        handler($0, voidSuccess($1), $2)
    }
}
