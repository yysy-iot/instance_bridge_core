//
//  ResultMapping.swift
//
//  Created by LCR on 2023/4/21.
//

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

public func toFlutterFailure(_ error: Error) -> FlutterError {
    let error = error as NSError
    return yyiNSErrorToFlutterError(error)
}


public func voidSuccess(_ success: @escaping (Any) -> Void) -> () -> Void {
    {
        success(0)
    }
}
