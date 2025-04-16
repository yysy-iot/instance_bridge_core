//
//  HashInstance.swift
//
//  Created by LCR on 2023/9/2.
//

import Foundation

open class HashInstance: Hashable {
    
    public var hashCode: Int64
    
    public static func == (lhs: HashInstance, rhs: HashInstance) -> Bool {
        lhs.hashCode == rhs.hashCode
    }
    
    public init(_ hashCode: Int64, _ arguments: Any?) {
        self.hashCode = hashCode
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashCode)
    }
}

open class ObjInstance: NSObject {
    
    public var hashCode: Int64
    
    public init(_ hashCode: Int64, _ arguments: Any?) {
        self.hashCode = hashCode
    }
}

