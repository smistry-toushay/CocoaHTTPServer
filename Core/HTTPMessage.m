#import "HTTPMessage.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#ifdef APPORTABLE
@interface HTTPMessage ()

@property (nonatomic, strong) NSMutableData *requestData;
@property (nonatomic) NSRange headerDataRange;

@property (nonatomic, strong) NSString *requestVersion;
@property (nonatomic, strong) NSString *requestMethod;
@property (nonatomic, strong) NSURL *requestURL;
@property (nonatomic, strong) NSMutableDictionary *requestHeaders;

@property (nonatomic) NSInteger responseCode;
@property (nonatomic) NSString *responseDescription;
@property (nonatomic) NSString *responseVersion;
@property (nonatomic, strong) NSMutableDictionary *responseHeaders;

@end
#endif


@implementation HTTPMessage

- (id)initEmptyRequest
{
	if ((self = [super init]))
	{
#ifdef APPORTABLE
        self.requestData = [[NSMutableData alloc] init];
        self.requestHeaders = [[NSMutableDictionary alloc] init];
#else
		message = CFHTTPMessageCreateEmpty(NULL, YES);
#endif
	}
	return self;
}

- (id)initRequestWithMethod:(NSString *)method URL:(NSURL *)url version:(NSString *)version
{
	if ((self = [super init]))
	{
#ifdef APPORTABLE
        // not implemented
#else
		message = CFHTTPMessageCreateRequest(NULL,
                                             (__bridge CFStringRef)method,
                                             (__bridge CFURLRef)url,
                                             (__bridge CFStringRef)version);
#endif
	}
	return self;
}

- (id)initResponseWithStatusCode:(NSInteger)code description:(NSString *)description version:(NSString *)version
{
	if ((self = [super init]))
	{
#ifdef APPORTABLE
        self.responseCode = code;
        self.responseDescription = description;
        self.responseVersion = version;
        
        self.responseHeaders = [[NSMutableDictionary alloc] init];
#else
		message = CFHTTPMessageCreateResponse(NULL,
		                                      (CFIndex)code,
		                                      (__bridge CFStringRef)description,
		                                      (__bridge CFStringRef)version);
#endif
	}
	return self;
}

- (void)dealloc
{
#ifdef APPORTABLE
#else
	if (message)
	{
		CFRelease(message);
	}
#endif
}

- (BOOL)appendData:(NSData *)data
{
#ifdef APPORTABLE
    [self.requestData appendData:data];
    
    return YES;
#else
	return CFHTTPMessageAppendBytes(message, [data bytes], [data length]);
#endif
}

- (BOOL)isHeaderComplete
{
#ifdef APPORTABLE
    NSRange searchRange = NSMakeRange(0, self.requestData.length);
    NSRange headerEndDataRange = [self.requestData rangeOfData:[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:searchRange];
    
    BOOL isHeaderComplete = (headerEndDataRange.location != NSNotFound);
    
    if (isHeaderComplete) {
        self.headerDataRange = NSMakeRange(0, headerEndDataRange.location);
        
        NSData *headerData = [self.requestData subdataWithRange:self.headerDataRange];
        NSString *header = [[NSString alloc] initWithData:headerData encoding:NSUTF8StringEncoding];
        
        NSArray *splitHeader = [header componentsSeparatedByString:@"\r\n"];
        
        if (splitHeader.count > 1) {
            NSString* firstLine = [splitHeader objectAtIndex:0];
            NSArray *splitFirstLine = [firstLine componentsSeparatedByString:@" "];
            
            self.requestMethod = [splitFirstLine objectAtIndex:0];
            self.requestURL = [NSURL URLWithString:[splitFirstLine objectAtIndex:1]];
            self.requestVersion = [splitFirstLine objectAtIndex:2];
            
            for (NSUInteger i = 1; i < splitHeader.count; i++) {
                NSString *headerLine = [splitHeader objectAtIndex:i];
                
                NSRange separatorRange = [headerLine rangeOfString:@": "];
                
                if (separatorRange.location != NSNotFound) {
                    NSString *headerField = [headerLine substringWithRange:NSMakeRange(0, separatorRange.location)];
                    NSString *headerFieldValue = [headerLine substringWithRange:NSMakeRange(separatorRange.location + separatorRange.length, headerLine.length - separatorRange.location - separatorRange.length)];
                    
                    [self.requestHeaders setObject:headerFieldValue forKey:headerField];
                }
            }
        }
    }
    
    return isHeaderComplete;
#else
	return CFHTTPMessageIsHeaderComplete(message);
#endif
}

- (NSString *)version
{
#ifdef APPORTABLE
    return self.requestVersion;
#else
	return (__bridge_transfer NSString *)CFHTTPMessageCopyVersion(message);
#endif
}

- (NSString *)method
{
#ifdef APPORTABLE
    return self.requestMethod;
#else
	return (__bridge_transfer NSString *)CFHTTPMessageCopyRequestMethod(message);
#endif
}

- (NSURL *)url
{
#ifdef APPORTABLE
    return self.requestURL;
#else
	return (__bridge_transfer NSURL *)CFHTTPMessageCopyRequestURL(message);
#endif
}

- (NSInteger)statusCode
{
#ifdef APPORTABLE
    return 0; // not implemented
#else
	return (NSInteger)CFHTTPMessageGetResponseStatusCode(message);
#endif
}

- (NSDictionary *)allHeaderFields
{
#ifdef APPORTABLE
    return nil; // not implemented
#else
	return (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(message);
#endif
}

- (NSString *)headerField:(NSString *)headerField
{
#ifdef APPORTABLE
    return [self.requestHeaders objectForKey:headerField];
#else
	return (__bridge_transfer NSString *)CFHTTPMessageCopyHeaderFieldValue(message, (__bridge CFStringRef)headerField);
#endif
}

- (void)setHeaderField:(NSString *)headerField value:(NSString *)headerFieldValue
{
#ifdef APPORTABLE
    [self.responseHeaders setObject:headerFieldValue forKey:headerField];
#else
	CFHTTPMessageSetHeaderFieldValue(message,
	                                 (__bridge CFStringRef)headerField,
	                                 (__bridge CFStringRef)headerFieldValue);
#endif
}

- (NSData *)messageData
{
#ifdef APPORTABLE
    NSMutableData *messageData = [[NSMutableData alloc] init];
    
    NSMutableString *header = [[NSMutableString alloc] init];
    
    if (self.responseDescription) {
        [header appendFormat:@"%@ %d %@\r\n", self.responseDescription, self.responseCode, self.responseVersion];
    } else {
        [header appendFormat:@"%@ %d\r\n", self.responseVersion, self.responseCode];
    }
    
    [self.responseHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        [header appendFormat:@"%@: %@\r\n", key, object];
    }];
    
    [header appendString:@"\r\n"];
    
    [messageData appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
    
    return messageData;
#else
	return (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(message);
#endif
}

- (NSData *)body
{
#ifdef APPORTABLE
    NSRange bodyRange = NSMakeRange(self.headerDataRange.length + 4, self.requestData.length - self.headerDataRange.length - 4);
    
    return [self.requestData subdataWithRange:bodyRange];
#else
	return (__bridge_transfer NSData *)CFHTTPMessageCopyBody(message);
#endif
}

- (void)setBody:(NSData *)body
{
#ifdef APPORTABLE
    // not implemented
#else
	CFHTTPMessageSetBody(message, (__bridge CFDataRef)body);
#endif
}

@end
