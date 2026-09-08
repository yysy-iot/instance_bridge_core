//
//  FlutterResponder.swift
//
//  Created by LCR on 2023/9/2.
//

import Foundation

public protocol FlutterResponder: AnyObject {
    
    init(_ hashCode: Int64, _ arguments: Any?)
    
    func callMethod(_ method: String, _ arguments: Any?, result: @escaping (Any) -> Void, error: @escaping (Error) -> Void)
}


