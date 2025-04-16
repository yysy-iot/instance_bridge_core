//
//  AnyDecoder.swift
//
//

import Foundation

/// `JSONDecoder` facilitates the decoding of JSON into semantic `Decodable` types.
open class AnyDecoder {
    // MARK: Options
    /// The strategy to use for decoding `Date` values.
    public enum DateDecodingStrategy {
        /// Defer to `Date` for decoding. This is the default strategy.
        case deferredToDate
        
        /// Decode the `Date` as a UNIX timestamp from a JSON number.
        case secondsSince1970
        
        /// Decode the `Date` as UNIX millisecond timestamp from a JSON number.
        case millisecondsSince1970
        
        /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
        case iso8601
        
        /// Decode the `Date` as a string parsed by the given formatter.
        case formatted(DateFormatter)
        
        /// Decode the `Date` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Date)
    }
    
    /// The strategy to use for decoding `Data` values.
    public enum DataDecodingStrategy {
        /// Defer to `Data` for decoding.
        case deferredToData
        
        /// Decode the `Data` from a Base64-encoded string. This is the default strategy.
        case base64
        
        /// Decode the `Data` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Data)
    }
    
    /// The strategy to use for non-JSON-conforming floating-point values (IEEE 754 infinity and NaN).
    public enum NonConformingFloatDecodingStrategy {
        /// Throw upon encountering non-conforming values. This is the default strategy.
        case `throw`
        
        /// Decode the values from the given representation strings.
        case convertFromString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
    
    /// The strategy to use for automatically changing the value of keys before decoding.
    public enum KeyDecodingStrategy {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys
        
        /// Provide a custom conversion from the key in the encoded JSON to the keys specified by the decoded types.
        /// The full path to the current decoding position is provided for context (in case you need to locate this key within the payload). The returned key is used in place of the last component in the coding path before decoding.
        /// If the result of the conversion is a duplicate key, then only one value will be present in the container for the type to decode from.
        case custom((_ codingPath: [CodingKey]) -> CodingKey)
    }
    
    /// The strategy to use in decoding dates. Defaults to `.deferredToDate`.
    open var dateDecodingStrategy: DateDecodingStrategy = .deferredToDate
    
    /// The strategy to use in decoding binary data. Defaults to `.base64`.
    open var dataDecodingStrategy: DataDecodingStrategy = .base64
    
    /// The strategy to use in decoding non-conforming numbers. Defaults to `.throw`.
    open var nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy = .throw
    
    /// The strategy to use for decoding keys. Defaults to `.useDefaultKeys`.
    open var keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys
    
    /// Contextual user-provided information for use during decoding.
    open var userInfo: [CodingUserInfoKey : Any] = [:]
    
    /// Options set on the top-level encoder to pass down the decoding hierarchy.
    fileprivate struct _Options {
        let dateDecodingStrategy: DateDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy
        let keyDecodingStrategy: KeyDecodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
    }
    
    /// The options set on the top-level decoder.
    fileprivate var options: _Options {
        _Options(dateDecodingStrategy: dateDecodingStrategy,
                 dataDecodingStrategy: dataDecodingStrategy,
                 nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy,
                 keyDecodingStrategy: keyDecodingStrategy,
                 userInfo: userInfo)
    }
    
    // MARK: - Constructing a JSON Decoder
    /// Initializes `self` with default strategies.
    public init() {}
    
    // MARK: - Decoding Values
    /// Decodes a top-level value of the given type from the given JSON representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    /// - throws: An error if any value throws an error during decoding.
    open func decode<T : Decodable>(_ type: T.Type, from any: Any) throws -> T {
        let decoder = AnyImplDecoder(referencing: any, options: options)
        guard let value = try decoder.unbox(any, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
        }
        
        return value
    }
}

fileprivate extension DecodingError {
    
    static func dcTypeMismatch(at codingPath: [CodingKey], expectation type: Any.Type, reality: Any) -> DecodingError {
        DecodingError.typeMismatch(type, .init(codingPath: codingPath, debugDescription: "\(reality)", underlyingError: nil))
    }
}

// MARK: - AnyImplDecoder
// NOTE: older overlays called this class _JSONDecoder. The two must
// coexist without a conflicting ObjC class name, so it was renamed.
// The old name must not be used in the new runtime.
private class AnyImplDecoder : Decoder {
    // MARK: Properties
    /// The decoder's storage.
    var storage: _AnyDecodingStorage
    
    /// Options set on the top-level decoder.
    let options: AnyDecoder._Options
    
    /// The path to the current point in encoding.
    fileprivate(set) public var codingPath: [CodingKey]
    
    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any] {
        options.userInfo
    }
    
    // MARK: - Initialization
    /// Initializes `self` with the given top-level container and options.
    init(referencing container: Any, at codingPath: [CodingKey] = [], options: AnyDecoder._Options) {
        storage = _AnyDecodingStorage()
        storage.push(container: container)
        self.codingPath = codingPath
        self.options = options
    }
    
    // MARK: - Decoder Methods
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard !(storage.topContainer is NSNull) else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<Key>.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }
        
        guard let topContainer = storage.topContainer as? [String : Any] else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: [String : Any].self, reality: storage.topContainer)
        }
    
        let container = _AnyKeyedDecodingContainer<Key>(referencing: self, wrapping: topContainer)
        return KeyedDecodingContainer(container)
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !(storage.topContainer is NSNull) else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Cannot get unkeyed decoding container -- found null value instead."))
        }
        
        guard let topContainer = storage.topContainer as? [Any] else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: [Any].self, reality: storage.topContainer)
        }
        
        return _JSONUnkeyedDecodingContainer(referencing: self, wrapping: topContainer)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        self
    }
}

// MARK: - Decoding Storage
private struct _AnyDecodingStorage {
    // MARK: Properties
    /// The container stack.
    /// Elements may be any one of the JSON types (NSNull, NSNumber, String, Array, [String : Any]).
    private(set) var containers: [Any] = []
    
    // MARK: - Initialization
    /// Initializes `self` with no containers.
    init() {}
    
    // MARK: - Modifying the Stack
    var count: Int {
        containers.count
    }
    
    var topContainer: Any {
        precondition(!containers.isEmpty, "Empty container stack.")
        return containers.last!
    }
    
    mutating func push(container: __owned Any) {
        containers.append(container)
    }
    
    mutating func popContainer() {
        precondition(!containers.isEmpty, "Empty container stack.")
        containers.removeLast()
    }
}

// MARK: Decoding Containers
private struct _AnyKeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
    typealias Key = K
    
    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: AnyImplDecoder
    
    /// A reference to the container we're reading from.
    private let container: [String : Any]
    
    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: AnyImplDecoder, wrapping container: [String : Any]) {
        self.decoder = decoder
        switch decoder.options.keyDecodingStrategy {
            case .useDefaultKeys:
                self.container = container
            case .custom(let converter):
                self.container = Dictionary(container.map {

                    key, value in (converter(decoder.codingPath + [_AnyDecoderKey(stringValue: key, intValue: nil)]).stringValue, value)
                }, uniquingKeysWith: { (first, _) in first })
        }
        codingPath = decoder.codingPath
    }
    
    // MARK: - KeyedDecodingContainerProtocol Methods
    public var allKeys: [Key] {
        container.keys.compactMap { Key(stringValue: $0) }
    }
    
    public func contains(_ key: Key) -> Bool {
        container[key.stringValue] != nil
    }
    
    private func _errorDescription(of key: CodingKey) -> String {
        "\(key) (\"\(key.stringValue)\")"
    }
    
    public func decodeNil(forKey key: Key) throws -> Bool {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        return entry is NSNull
    }
    
    public func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func decode<T : Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: codingPath,
                                                                  debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \(_errorDescription(of: key))"))
        }
        
        guard let dictionary = value as? [String : Any] else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: [String : Any].self, reality: value)
        }
        
        let container = _AnyKeyedDecodingContainer<NestedKey>(referencing: decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }
    
    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: codingPath,
                                                                  debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found for key \(_errorDescription(of: key))"))
        }
        
        guard let array = value as? [Any] else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: [Any].self, reality: value)
        }
        
        return _JSONUnkeyedDecodingContainer(referencing: decoder, wrapping: array)
    }
    
    private func _superDecoder(forKey key: __owned CodingKey) throws -> Decoder {
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        let value: Any = container[key.stringValue] ?? NSNull()
        return AnyImplDecoder(referencing: value, at: decoder.codingPath, options: decoder.options)
    }
    
    public func superDecoder() throws -> Decoder {
        try _superDecoder(forKey: _AnyDecoderKey.super)
    }
    
    public func superDecoder(forKey key: Key) throws -> Decoder {
        try _superDecoder(forKey: key)
    }
}

private struct _JSONUnkeyedDecodingContainer : UnkeyedDecodingContainer {
    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: AnyImplDecoder
    
    /// A reference to the container we're reading from.
    private let container: [Any]
    
    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]
    
    /// The index of the element we're about to decode.
    private(set) public var currentIndex: Int
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: AnyImplDecoder, wrapping container: [Any]) {
        self.decoder = decoder
        self.container = container
        codingPath = decoder.codingPath
        currentIndex = 0
    }
    
    // MARK: - UnkeyedDecodingContainer Methods
    public var count: Int? {
        container.count
    }
    
    public var isAtEnd: Bool {
        currentIndex >= count!
    }
    
    public mutating func decodeNil() throws -> Bool {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        if container[currentIndex] is NSNull {
            currentIndex += 1
            return true
        } else {
            return false
        }
    }
    
    public mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: Int.Type) throws -> Int {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: Int8.Type) throws -> Int8 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: Int16.Type) throws -> Int16 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: Int32.Type) throws -> Int32 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: Int64.Type) throws -> Int64 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: UInt.Type) throws -> UInt {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: Float.Type) throws -> Float {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: Double.Type) throws -> Double {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode(_ type: String.Type) throws -> String {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func decode<T : Decodable>(_ type: T.Type) throws -> T {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard let decoded = try decoder.unbox(container[currentIndex], as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_AnyDecoderKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        currentIndex += 1
        return decoded
    }
    
    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }
        
        let value = container[currentIndex]
        guard !(value is NSNull) else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }
        
        guard let dictionary = value as? [String : Any] else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: [String : Any].self, reality: value)
        }
        
        currentIndex += 1
        let container = _AnyKeyedDecodingContainer<NestedKey>(referencing: decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }
        
        let value = container[currentIndex]
        guard !(value is NSNull) else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }
        
        guard let array = value as? [Any] else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: [Any].self, reality: value)
        }
        
        currentIndex += 1
        return _JSONUnkeyedDecodingContainer(referencing: decoder, wrapping: array)
    }
    
    public mutating func superDecoder() throws -> Decoder {
        decoder.codingPath.append(_AnyDecoderKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }
        
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Cannot get superDecoder() -- unkeyed container is at end."))
        }
        
        let value = container[currentIndex]
        currentIndex += 1
        return AnyImplDecoder(referencing: value, at: decoder.codingPath, options: decoder.options)
    }
}

extension AnyImplDecoder : SingleValueDecodingContainer {
    // MARK: SingleValueDecodingContainer Methods
    private func expectNonNull<T>(_ type: T.Type) throws {
        guard !decodeNil() else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but found null value instead."))
        }
    }
    
    public func decodeNil() -> Bool {
        storage.topContainer is NSNull
    }
    
    public func decode(_ type: Bool.Type) throws -> Bool {
        try expectNonNull(Bool.self)
        return try self.unbox(storage.topContainer, as: Bool.self)!
    }
    
    public func decode(_ type: Int.Type) throws -> Int {
        try expectNonNull(Int.self)
        return try self.unbox(storage.topContainer, as: Int.self)!
    }
    
    public func decode(_ type: Int8.Type) throws -> Int8 {
        try expectNonNull(Int8.self)
        return try self.unbox(storage.topContainer, as: Int8.self)!
    }
    
    public func decode(_ type: Int16.Type) throws -> Int16 {
        try expectNonNull(Int16.self)
        return try self.unbox(storage.topContainer, as: Int16.self)!
    }
    
    public func decode(_ type: Int32.Type) throws -> Int32 {
        try expectNonNull(Int32.self)
        return try self.unbox(storage.topContainer, as: Int32.self)!
    }
    
    public func decode(_ type: Int64.Type) throws -> Int64 {
        try expectNonNull(Int64.self)
        return try self.unbox(storage.topContainer, as: Int64.self)!
    }
    
    public func decode(_ type: UInt.Type) throws -> UInt {
        try expectNonNull(UInt.self)
        return try self.unbox(storage.topContainer, as: UInt.self)!
    }
    
    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        try expectNonNull(UInt8.self)
        return try self.unbox(storage.topContainer, as: UInt8.self)!
    }
    
    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        try expectNonNull(UInt16.self)
        return try self.unbox(storage.topContainer, as: UInt16.self)!
    }
    
    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        try expectNonNull(UInt32.self)
        return try self.unbox(storage.topContainer, as: UInt32.self)!
    }
    
    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        try expectNonNull(UInt64.self)
        return try self.unbox(storage.topContainer, as: UInt64.self)!
    }
    
    public func decode(_ type: Float.Type) throws -> Float {
        try expectNonNull(Float.self)
        return try self.unbox(storage.topContainer, as: Float.self)!
    }
    
    public func decode(_ type: Double.Type) throws -> Double {
        try expectNonNull(Double.self)
        return try self.unbox(storage.topContainer, as: Double.self)!
    }
    
    public func decode(_ type: String.Type) throws -> String {
        try expectNonNull(String.self)
        return try self.unbox(storage.topContainer, as: String.self)!
    }
    
    public func decode<T : Decodable>(_ type: T.Type) throws -> T {
        try expectNonNull(type)
        return try self.unbox(storage.topContainer, as: type)!
    }
}

// MARK: - Concrete Value Representations
private extension AnyImplDecoder {
    /// Returns the given value unboxed from a container.
    func unbox(_ value: Any, as type: Bool.Type) throws -> Bool? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? NSNumber {
            // TODO: Add a flag to coerce non-boolean numbers into Bools?
            if number === kCFBooleanTrue as NSNumber {
                return true
            } else if number === kCFBooleanFalse as NSNumber {
                return false
            }
            
            /* FIXME: If swift-corelibs-foundation doesn't change to use NSNumber, this code path will need to be included and tested:
             } else if let bool = value as? Bool {
             return bool
             */
            
        }
        
        throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: Int.Type) throws -> Int? {
        guard !(value is NSNull) else { return nil }
        
        guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
        }
        
        let int = number.intValue
        guard NSNumber(value: int) == number else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Parsed JSON number <\(number)> does not fit in \(type)."))
        }
        
        return int
    }
    
    func unbox(_ value: Any, as type: Int8.Type) throws -> Int8? {
        guard !(value is NSNull) else { return nil }
        
        guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
        }
        
        let int8 = number.int8Value
        guard NSNumber(value: int8) == number else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Parsed JSON number <\(number)> does not fit in \(type)."))
        }
        
        return int8
    }
    
    func unbox(_ value: Any, as type: Int16.Type) throws -> Int16? {
        guard !(value is NSNull) else { return nil }
        
        guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
        }
        
        let int16 = number.int16Value
        guard NSNumber(value: int16) == number else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Parsed JSON number <\(number)> does not fit in \(type)."))
        }
        
        return int16
    }
    
    func unbox(_ value: Any, as type: Int32.Type) throws -> Int32? {
        guard !(value is NSNull) else { return nil }
        
        guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
        }
        
        let int32 = number.int32Value
        guard NSNumber(value: int32) == number else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Parsed JSON number <\(number)> does not fit in \(type)."))
        }
        
        return int32
    }
    
    func unbox(_ value: Any, as type: Int64.Type) throws -> Int64? {
        guard !(value is NSNull) else { return nil }
        
        guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
        }
        
        let int64 = number.int64Value
        guard NSNumber(value: int64) == number else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Parsed JSON number <\(number)> does not fit in \(type)."))
        }
        
        return int64
    }
    
    func unbox(_ value: Any, as type: UInt.Type) throws -> UInt? {
        guard !(value is NSNull) else { return nil }
        
        guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
        }
        
        let uint = number.uintValue
        guard NSNumber(value: uint) == number else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Parsed JSON number <\(number)> does not fit in \(type)."))
        }
        
        return uint
    }
    
    func unbox(_ value: Any, as type: UInt8.Type) throws -> UInt8? {
        guard !(value is NSNull) else { return nil }
        
        guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
        }
        
        let uint8 = number.uint8Value
        guard NSNumber(value: uint8) == number else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Parsed JSON number <\(number)> does not fit in \(type)."))
        }
        
        return uint8
    }
    
    func unbox(_ value: Any, as type: UInt16.Type) throws -> UInt16? {
        guard !(value is NSNull) else { return nil }
        
        guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
        }
        
        let uint16 = number.uint16Value
        guard NSNumber(value: uint16) == number else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Parsed JSON number <\(number)> does not fit in \(type)."))
        }
        
        return uint16
    }
    
    func unbox(_ value: Any, as type: UInt32.Type) throws -> UInt32? {
        guard !(value is NSNull) else { return nil }
        
        guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
        }
        
        let uint32 = number.uint32Value
        guard NSNumber(value: uint32) == number else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Parsed JSON number <\(number)> does not fit in \(type)."))
        }
        
        return uint32
    }
    
    func unbox(_ value: Any, as type: UInt64.Type) throws -> UInt64? {
        guard !(value is NSNull) else { return nil }
        
        guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
        }
        
        let uint64 = number.uint64Value
        guard NSNumber(value: uint64) == number else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Parsed JSON number <\(number)> does not fit in \(type)."))
        }
        
        return uint64
    }
    
    func unbox(_ value: Any, as type: Float.Type) throws -> Float? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse {
            // We are willing to return a Float by losing precision:
            // * If the original value was integral,
            //   * and the integral value was > Float.greatestFiniteMagnitude, we will fail
            //   * and the integral value was <= Float.greatestFiniteMagnitude, we are willing to lose precision past 2^24
            // * If it was a Float, you will get back the precise value
            // * If it was a Double or Decimal, you will get back the nearest approximation if it will fit
            let double = number.doubleValue
            guard abs(double) <= Double(Float.greatestFiniteMagnitude) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Parsed JSON number \(number) does not fit in \(type)."))
            }
            
            return Float(double)
            
            /* FIXME: If swift-corelibs-foundation doesn't change to use NSNumber, this code path will need to be included and tested:
             } else if let double = value as? Double {
             if abs(double) <= Double(Float.max) {
             return Float(double)
             }
             overflow = true
             } else if let int = value as? Int {
             if let float = Float(exactly: int) {
             return float
             }
             overflow = true
             */
            
        } else if let string = value as? String,
                  case .convertFromString(let posInfString, let negInfString, let nanString) = options.nonConformingFloatDecodingStrategy {
            if string == posInfString {
                return Float.infinity
            } else if string == negInfString {
                return -Float.infinity
            } else if string == nanString {
                return Float.nan
            }
        }
        
        throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: Double.Type) throws -> Double? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse {
            // We are always willing to return the number as a Double:
            // * If the original value was integral, it is guaranteed to fit in a Double; we are willing to lose precision past 2^53 if you encoded a UInt64 but requested a Double
            // * If it was a Float or Double, you will get back the precise value
            // * If it was Decimal, you will get back the nearest approximation
            return number.doubleValue
            
            /* FIXME: If swift-corelibs-foundation doesn't change to use NSNumber, this code path will need to be included and tested:
             } else if let double = value as? Double {
             return double
             } else if let int = value as? Int {
             if let double = Double(exactly: int) {
             return double
             }
             overflow = true
             */
            
        } else if let string = value as? String,
                  case .convertFromString(let posInfString, let negInfString, let nanString) = options.nonConformingFloatDecodingStrategy {
            if string == posInfString {
                return Double.infinity
            } else if string == negInfString {
                return -Double.infinity
            } else if string == nanString {
                return Double.nan
            }
        }
        
        throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: String.Type) throws -> String? {
        guard !(value is NSNull) else { return nil }
        
        guard let string = value as? String else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
        }
        
        return string
    }
    
    func unbox(_ value: Any, as type: Date.Type) throws -> Date? {
        guard !(value is NSNull) else { return nil }
        
        switch options.dateDecodingStrategy {
            case .deferredToDate:
                storage.push(container: value)
                defer { storage.popContainer() }
                return try Date(from: self)
                
            case .secondsSince1970:
                let double = try self.unbox(value, as: Double.self)!
                return Date(timeIntervalSince1970: double)
                
            case .millisecondsSince1970:
                let double = try self.unbox(value, as: Double.self)!
                return Date(timeIntervalSince1970: double / 1000.0)
                
            case .iso8601:
                if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                    let string = try self.unbox(value, as: String.self)!
                    guard let date = _iso8601Formatter.date(from: string) else {
                        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
                    }
                    
                    return date
                } else {
                    fatalError("ISO8601DateFormatter is unavailable on this platform.")
                }
                
            case .formatted(let formatter):
                let string = try self.unbox(value, as: String.self)!
                guard let date = formatter.date(from: string) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Date string does not match format expected by formatter."))
                }
                
                return date
                
            case .custom(let closure):
                storage.push(container: value)
                defer { storage.popContainer() }
                return try closure(self)
        }
    }
    
    func unbox(_ value: Any, as type: Data.Type) throws -> Data? {
        guard !(value is NSNull) else { return nil }
        
        switch options.dataDecodingStrategy {
            case .deferredToData:
                storage.push(container: value)
                defer { storage.popContainer() }
                return try Data(from: self)
                
            case .base64:
                guard let string = value as? String else {
                    throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
                }
                
                guard let data = Data(base64Encoded: string) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Encountered Data is not valid Base64."))
                }
                
                return data
                
            case .custom(let closure):
                storage.push(container: value)
                defer { storage.popContainer() }
                return try closure(self)
        }
    }
    
    func unbox(_ value: Any, as type: Decimal.Type) throws -> Decimal? {
        guard !(value is NSNull) else { return nil }
        
        // Attempt to bridge from NSDecimalNumber.
        if let decimal = value as? Decimal {
            return decimal
        } else {
            let doubleValue = try self.unbox(value, as: Double.self)!
            return Decimal(doubleValue)
        }
    }
    
    func unbox<T>(_ value: Any, as type: _AnyStrDictionaryDecodableMarker.Type) throws -> T? {
        guard !(value is NSNull) else { return nil }
        
        var result = [String : Any]()
        guard let dict = value as? NSDictionary else {
            throw DecodingError.dcTypeMismatch(at: codingPath, expectation: type, reality: value)
        }
        let elementType = type.elementType
        for (key, value) in dict {
            let key = key as! String
            codingPath.append(_AnyDecoderKey(stringValue: key, intValue: nil))
            defer { codingPath.removeLast() }
            
            result[key] = try unbox_(value, as: elementType)
        }
        
        return result as? T
    }
    
    func unbox<T : Decodable>(_ value: Any, as type: T.Type) throws -> T? {
        try unbox_(value, as: type) as? T
    }
    
    func unbox_(_ value: Any, as type: Decodable.Type) throws -> Any? {
        if type == Date.self || type == NSDate.self {
            return try self.unbox(value, as: Date.self)
        } else if type == Data.self || type == NSData.self {
            return try self.unbox(value, as: Data.self)
        } else if type == URL.self || type == NSURL.self {
            guard let urlString = try self.unbox(value, as: String.self) else {
                return nil
            }
            
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath,
                                                                        debugDescription: "Invalid URL string."))
            }
            return url
        } else if type == Decimal.self || type == NSDecimalNumber.self {
            return try self.unbox(value, as: Decimal.self)
        } else if let stringKeyedDictType = type as? _AnyStrDictionaryDecodableMarker.Type {
            return try self.unbox(value, as: stringKeyedDictType)
        } else {
            storage.push(container: value)
            defer { storage.popContainer() }
            return try type.init(from: self)
        }
    }
}


//===----------------------------------------------------------------------===//
// Shared Key Types
//===----------------------------------------------------------------------===//
private struct _AnyDecoderKey : CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    public init?(intValue: Int) {
        stringValue = "\(intValue)"
        self.intValue = intValue
    }

    public init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }

    init(index: Int) {
        stringValue = "Index \(index)"
        intValue = index
    }

    static let `super` = _AnyDecoderKey(stringValue: "super")!
}


private protocol _AnyStrDictionaryDecodableMarker {
    static var elementType: Decodable.Type { get }
}


extension Dictionary : _AnyStrDictionaryDecodableMarker where Key == String, Value: Decodable {
    static var elementType: Decodable.Type { Value.self }
}


private var _iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()
