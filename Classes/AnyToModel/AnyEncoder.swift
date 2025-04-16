//
//  StringsEncoder.swift
//
//

import Foundation

public struct AnyEncoder {
    
    public func encode<T: Encodable>(_ value: T) throws -> NSCoding {
        let stringsEncoding = AnyImplEncoder()
        try value.encode(to: stringsEncoding)
        return stringsEncoding.data.value
    }
    
    public init() { }
}


private struct AnyImplEncoder: Encoder {
    
    
    fileprivate final class Data {
        
        private var obj: NSCoding?
        
        var value: NSCoding {
            obj ?? NSNull()
        }
        
        func encode(value: NSCoding) {
            obj = value
        }
    }
    
    
    fileprivate let data: Data
    
    let codingPath: [CodingKey]
    
    let userInfo: [CodingUserInfoKey : Any] = [:]
    
    
    init(to data: Data = Data(), codingPath: [CodingKey] = []) {
        self.data = data
        self.codingPath = codingPath
    }
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        let container = NSMutableDictionary()
        data.encode(value: container)
        return KeyedEncodingContainer(DictionaryKeyedEncoding<Key>(to: data, codingPath: codingPath, container: container))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let array = NSMutableArray()
        data.encode(value: array)
        return DictionaryUnkeyedEncoding(to: data, codingPath: codingPath, container: array)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        DictionarySingleValueEncoding(to: data, codingPath: codingPath)
    }
}

/// 键值对编码
private struct DictionaryKeyedEncoding<Key: CodingKey>: KeyedEncodingContainerProtocol {
    
    private let data: AnyImplEncoder.Data
    private let container: NSMutableDictionary
    let codingPath: [CodingKey]
    
    init(to data: AnyImplEncoder.Data, codingPath: [CodingKey], container: NSMutableDictionary) {
        self.data = data
        self.codingPath = codingPath
        self.container = container
    }
    
    mutating func encodeNil(forKey key: Key) throws { }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        container[key.stringValue] = value
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        container[key.stringValue] = NSNumber(value: value)
    }
    
    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        let encoding = AnyImplEncoder(codingPath: codingPath + [key])
        try value.encode(to: encoding)
        container[key.stringValue] = encoding.data.value
    }
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let subContainer = NSMutableDictionary()
        container[key.stringValue] = subContainer
        return KeyedEncodingContainer(DictionaryKeyedEncoding<NestedKey>(to: data, codingPath: codingPath + [key], container: subContainer))
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let array = NSMutableArray()
        container[key.stringValue] = array
        return DictionaryUnkeyedEncoding(to: data, codingPath: codingPath + [key], container: array)
    }
    
    mutating func superEncoder() -> Encoder {
        AnyImplEncoder(to: data, codingPath: codingPath + [IndexedCodingKey.super])
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        AnyImplEncoder(to: data, codingPath: codingPath + [key])
    }
}


/// 数组编码
fileprivate struct DictionaryUnkeyedEncoding: UnkeyedEncodingContainer {
    
    private let data: AnyImplEncoder.Data
    private let container: NSMutableArray
    let codingPath: [CodingKey]
    
    init(to data: AnyImplEncoder.Data, codingPath: [CodingKey], container: NSMutableArray) {
        self.data = data
        self.container = container
        self.codingPath = codingPath
    }
    
    private(set) var count: Int = 0
    
    mutating func encodeNil() throws {
        count += 1
    }
    
    mutating func encode(_ value: Bool) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode(_ value: String) throws {
        container.add(value as NSString)
        count += 1
    }
    
    mutating func encode(_ value: Double) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode(_ value: Float) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode(_ value: Int) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode(_ value: Int8) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode(_ value: Int16) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode(_ value: Int32) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode(_ value: Int64) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode(_ value: UInt) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode(_ value: UInt8) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode(_ value: UInt16) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode(_ value: UInt32) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode(_ value: UInt64) throws {
        container.add(NSNumber(value: value))
        count += 1
    }
    
    mutating func encode<T: Encodable>(_ value: T) throws {
        let encoding = AnyImplEncoder(codingPath: codingPath + [IndexedCodingKey(intValue: count)])
        try value.encode(to: encoding)
        container.add(encoding.data.value)
        count += 1
    }
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        let subContainer = NSMutableDictionary()
        container.add(subContainer)
        defer { count += 1 }
        return KeyedEncodingContainer(DictionaryKeyedEncoding<NestedKey>(to: data, codingPath: codingPath + [IndexedCodingKey(intValue: count)], container: subContainer))
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let array = NSMutableArray()
        container.add(array)
        defer { count += 1 }
        return DictionaryUnkeyedEncoding(to: data, codingPath: codingPath + [IndexedCodingKey(intValue: count)], container: array)
    }
    
    mutating func superEncoder() -> Encoder {
        AnyImplEncoder(to: data, codingPath: codingPath + [IndexedCodingKey.super])
    }
}


///
fileprivate struct DictionarySingleValueEncoding: SingleValueEncodingContainer {
    
    private let data: AnyImplEncoder.Data
    let codingPath: [CodingKey]
    
    init(to data: AnyImplEncoder.Data, codingPath: [CodingKey]) {
        self.data = data
        self.codingPath = codingPath
    }
    
    mutating func encodeNil() throws {
        data.encode(value: NSNull())
    }
    
    mutating func encode(_ value: Bool) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode(_ value: String) throws {
        data.encode(value: value as NSString)
    }
    
    mutating func encode(_ value: Double) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode(_ value: Float) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode(_ value: Int) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode(_ value: Int8) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode(_ value: Int16) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode(_ value: Int32) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode(_ value: Int64) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode(_ value: UInt) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode(_ value: UInt8) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode(_ value: UInt16) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode(_ value: UInt32) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode(_ value: UInt64) throws {
        data.encode(value: NSNumber(value: value))
    }
    
    mutating func encode<T: Encodable>(_ value: T) throws {
        let stringsEncoding = AnyImplEncoder(to: data, codingPath: codingPath)
        try value.encode(to: stringsEncoding)
        data.encode(value: stringsEncoding.data.value)
    }
}

fileprivate struct IndexedCodingKey: CodingKey {
    
    let intValue: Int?
    let stringValue: String
    
    init(intValue: Int) {
        self.intValue = intValue
        stringValue = intValue.description
    }
    
    init(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }
    
    static let `super` = IndexedCodingKey(stringValue: "super")
}
