//
//  FlutterErrorExt.h
//  Pods
//
//  Created by LCR on 2024/10/17.
//

#ifndef FlutterErrorExt_h
#define FlutterErrorExt_h

#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import <Flutter/Flutter.h>
#endif
#import <Foundation/Foundation.h>

typedef FlutterError* _Nonnull (^FlutterErrorConvertHandler)(NSError* _Nonnull error);


NSString* _Nonnull yyiErrCodeStr(NSError* _Nonnull error);

void yyiErrorUserInfoAddFlutterErrorDetails(NSDictionary<NSErrorUserInfoKey, id> * _Nullable userInfo,
                                            NSErrorUserInfoKey _Nonnull key,
                                            NSMutableDictionary<NSString*, id> * _Nonnull details);

NSDictionary* _Nonnull yyiNSErrorGetDetails(NSErrorDomain _Nonnull domain, NSDictionary<NSErrorUserInfoKey, id> * _Nullable userInfo);

// 全局 setter 和 getter
void yyiSetNSErrorToFlutterErrorHandler(FlutterErrorConvertHandler _Nonnull handler);
FlutterError* _Nonnull yyiNSErrorToFlutterError(NSError* _Nonnull error); // 包装后的统一调用口

#endif /* FlutterErrorExt_h */
