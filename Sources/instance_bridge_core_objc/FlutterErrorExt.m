#import "FlutterErrorExt.h"

///
NSString* yyiErrCodeStr(NSError* error) {
    return [NSString stringWithFormat:@"%li", error.code];
}

///
void yyiErrorUserInfoAddFlutterErrorDetails(NSDictionary<NSErrorUserInfoKey, id> *userInfo,
                                            NSErrorUserInfoKey key,
                                            NSMutableDictionary<NSString*, id> *details) {
    id value = userInfo[key];
    if (value != nil && [value isKindOfClass:NSString.class]) {
        details[key] = value;
    }
}

///
NSDictionary* yyiNSErrorGetDetails(NSErrorDomain domain, NSDictionary<NSErrorUserInfoKey, id> *userInfo) {
    NSMutableDictionary<NSString*, id> *details = [NSMutableDictionary dictionaryWithObject:domain forKey:@"domain"];
    if (userInfo == nil) return details;
    id underlyingError = userInfo[NSUnderlyingErrorKey];
    if (underlyingError != nil && [underlyingError isKindOfClass:NSError.class]) {
        NSError *error = underlyingError;
        details[NSUnderlyingErrorKey] = @{@"code": yyiErrCodeStr(error),
                                          @"message": error.localizedDescription,
                                          @"details": yyiNSErrorGetDetails(error.domain, error.userInfo)};
    }
    //
    yyiErrorUserInfoAddFlutterErrorDetails(userInfo, NSLocalizedFailureReasonErrorKey, details);
    yyiErrorUserInfoAddFlutterErrorDetails(userInfo, NSLocalizedRecoverySuggestionErrorKey, details);
    yyiErrorUserInfoAddFlutterErrorDetails(userInfo, NSHelpAnchorErrorKey, details);
    yyiErrorUserInfoAddFlutterErrorDetails(userInfo, NSDebugDescriptionErrorKey, details);
    yyiErrorUserInfoAddFlutterErrorDetails(userInfo, NSLocalizedFailureErrorKey, details);
    
    return details;
}

static FlutterErrorConvertHandler _flutterErrorHandler = nil;

void yyiSetNSErrorToFlutterErrorHandler(FlutterErrorConvertHandler handler) {
    _flutterErrorHandler = handler;
}

FlutterError* yyiNSErrorToFlutterError(NSError* error) {
    if (_flutterErrorHandler) {
        return _flutterErrorHandler(error);
    } else {
        NSString *localizedDescription = error.localizedDescription;
        NSDictionary<NSErrorUserInfoKey, id> *userInfo = error.userInfo;
        return [FlutterError errorWithCode: yyiErrCodeStr(error)
                                   message: localizedDescription
                                   details: yyiNSErrorGetDetails(error.domain, userInfo)];
    }
}
