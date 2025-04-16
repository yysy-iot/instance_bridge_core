//
//  FlutterRequestError.swift
//
//  Created by LCR on 2023/4/21.
//

import Foundation



public enum FlutterRequestError: Error, CustomNSError, LocalizedError {
    case invalidArgument
    case invalidObject
    case notImplemented
    case cancel
    
    public static var errorDomain: String { "YYPlatformError" }
    
    public var errorCode: Int {
        switch self {
        case .invalidObject:
            return 405
        case .invalidArgument:
            return 400
        case.notImplemented:
            return 404
        case .cancel:
            return 409
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .invalidArgument:
            return "无效参数"
        case .invalidObject:
            return "无效对象"
        case .notImplemented:
            return "未实现"
        case .cancel:
            return "cancel"
        }
    }
}
