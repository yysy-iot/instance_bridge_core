//
//  Dictionary+Mapping.swift
//
//  Created by LCR on 2022/7/7.
//

import Flutter


///
public extension Dictionary where Key == String, Value == Any {
    
    ///
    init<T: Encodable>(from model: T) throws {
        let obj = try AnyEncoder().encode(model)
        guard let result = obj as? [String: Any] else {
            throw EncodingError.invalidValue(model, .init(codingPath: [], debugDescription: "无法正确转成dictionary"))
        }
        self = result
    }
    
    init(error: Error) {
        let error = error as NSError
        self = ["domain": error.domain,
                "code": error.code,
                "message": error.localizedDescription]
//        "details": error.userInfo
    }
}


public extension AnyDecoder {
    
    static func decode<T : Decodable>(_ type: T.Type, from any: Any?) -> T? {
        guard let any = any else { return nil }
        return try? AnyDecoder().decode(T.self, from: any)
    }
    
    
    static func decode<T : Decodable>(_ type: T.Type, from any: Any?) throws -> T {
        guard let any = any else {
            throw DecodingError.valueNotFound(type, .init(codingPath: [], debugDescription: "value is empty"))
        }
        return try AnyDecoder().decode(T.self, from: any)
    }
}
