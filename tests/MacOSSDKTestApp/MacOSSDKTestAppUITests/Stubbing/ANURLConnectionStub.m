/*   Copyright 2014 APPNEXUS INC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "ANURLConnectionStub.h"
@import AppNexusNativeMacOSSDK;
#import "ANHTTPStubURLProtocol.h"

@implementation ANURLConnectionStub

- (id)copyWithZone:(NSZone *)zone {
    ANURLConnectionStub *newStub = [[ANURLConnectionStub alloc] init];
    newStub.requestURL = self.requestURL;
    newStub.responseCode = self.responseCode;
    newStub.responseBody = self.responseBody;
    return newStub;
}

- (BOOL)isEqual:(ANURLConnectionStub *)object {
    BOOL sameRequestURLString = [self.requestURL isEqualToString:object.requestURL];
    BOOL sameResponseCode = (self.responseCode == object.responseCode);
    BOOL sameResponseBody = [self.responseBody isEqualToString:object.responseBody];
    return sameRequestURLString && sameResponseBody && sameResponseCode;
}

- (NSUInteger)hash {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendString:self.requestURL];
    [description appendString:[NSString stringWithFormat:@"%ld", (long)self.responseCode]];
    [description appendString:self.responseBody];
    return [description hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"NSURLConnectionStub: \n\
    Request URL Pattern: %@,\n\
    Response Code: %ld,\n\
    Response Body: %@",self.requestURL, (long)self.responseCode, self.responseBody];

}




#pragma mark - Pre-Initialized Stubbers

+ (ANURLConnectionStub *)stubForStandardBannerWithAdSize:(CGSize)adSize
                                     contentFromResource:(NSString *)resource
                                                  ofType:(NSString *)type {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:resource
                                                         ofType:type];
    NSString *content = [[NSString alloc] initWithContentsOfFile:filePath
                                                        encoding:NSUTF8StringEncoding
                                                           error:nil];
    return [ANURLConnectionStub stubForStandardBannerWithAdSize:adSize
                                                        content:content];
}

+ (ANURLConnectionStub *)stubForStandardBannerWithAdSize:(CGSize)adSize
                                                 content:(NSString *)content {
    ANURLConnectionStub *stub = [[ANURLConnectionStub alloc] init];
    stub.requestURL = @"https://mediation.adnxs.com/ut/v3";
    stub.responseCode = 200;
    stub.responseBody = [NSJSONSerialization dataWithJSONObject:[[self class] responseForStandardBannerWithAdSize:adSize
                                                                                                          content:content]
                                                        options:0
                                                          error:nil];
    return stub;
}

+ (ANURLConnectionStub *)stubForMraidFile {
    ANURLConnectionStub *stub = [[ANURLConnectionStub alloc] init];
    stub.responseBody = @"";
    stub.responseCode = 200;
    return stub;
}

+ (ANURLConnectionStub *)stubForResource:(NSString *)resource
                                  ofType:(NSString *)type {
    return [ANURLConnectionStub stubForResource:resource
                                         ofType:type
               withRequestURL:resource
                                       inBundle:[NSBundle mainBundle]];
}

+ (ANURLConnectionStub *)stubForResource:(NSString *)resource
                                  ofType:(NSString *)type
        withRequestURL:(NSString *)pattern {
    return [ANURLConnectionStub stubForResource:resource
                                         ofType:type
               withRequestURL:pattern
                                       inBundle:[NSBundle mainBundle]];
}

+ (ANURLConnectionStub *)stubForResource:(NSString *)resource
                                  ofType:(NSString *)type
        withRequestURL:(NSString *)pattern
                                inBundle:(NSBundle *)bundle {
    ANURLConnectionStub *stub = [[ANURLConnectionStub alloc] init];
    stub.responseCode = 200;
    stub.requestURL = pattern;
    stub.responseBody = [NSData dataWithContentsOfFile:[bundle pathForResource:resource
                                                                        ofType:type]];
    return stub;
}

+ (NSDictionary *)responseForStandardBannerWithAdSize:(CGSize)adSize
                                              content:(NSString *)content {
    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    response[@"status"] = @"ok";
    NSDictionary *adElement = [[self class] adElementForAdType:@"banner"
                                                        adSize:adSize
                                                       content:content];
    response[@"ads"] = @[adElement];
    return [response copy];
}

+ (NSDictionary *)adElementForAdType:(NSString *)type
                              adSize:(CGSize)adSize
                             content:(NSString *)content {
    NSMutableDictionary *adElement = [[NSMutableDictionary alloc] init];
    adElement[@"type"] = type;
    adElement[@"width"] = [@(adSize.width) description];
    adElement[@"height"] = [@(adSize.height) description];
    adElement[@"content"] = content;
    return [adElement copy];
}

+ (void)setEnabled:(BOOL)enable forSessionConfiguration:(NSURLSessionConfiguration*)sessionConfig
{
    // Runtime check to make sure the API is available on this version
    if (   [sessionConfig respondsToSelector:@selector(protocolClasses)]
        && [sessionConfig respondsToSelector:@selector(setProtocolClasses:)])
    {
        NSMutableArray * urlProtocolClasses = [NSMutableArray arrayWithArray:sessionConfig.protocolClasses];
        Class protoCls = ANHTTPStubURLProtocol.class;
        if (enable && ![urlProtocolClasses containsObject:protoCls])
        {
            [urlProtocolClasses insertObject:protoCls atIndex:0];
        }
        else if (!enable && [urlProtocolClasses containsObject:protoCls])
        {
            [urlProtocolClasses removeObject:protoCls];
        }
        sessionConfig.protocolClasses = urlProtocolClasses;
    }
    else
    {
        NSLog(@"[ANURLConnectionStub] %@ is only available when running on iOS7+/OSX9+. "
              @"Use conditions like 'if ([NSURLSessionConfiguration class])' to only call "
              @"this method if the user is running iOS7+/OSX9+.", NSStringFromSelector(_cmd));
    }
}

+ (BOOL)isEnabledForSessionConfiguration:(NSURLSessionConfiguration *)sessionConfig
{
    // Runtime check to make sure the API is available on this version
    if (   [sessionConfig respondsToSelector:@selector(protocolClasses)]
        && [sessionConfig respondsToSelector:@selector(setProtocolClasses:)])
    {
        NSMutableArray * urlProtocolClasses = [NSMutableArray arrayWithArray:sessionConfig.protocolClasses];
        Class protoCls = ANHTTPStubURLProtocol.class;
        return [urlProtocolClasses containsObject:protoCls];
    }
    else
    {
        NSLog(@"[ANURLConnectionStub] %@ is only available when running on iOS7+/OSX9+. "
              @"Use conditions like 'if ([NSURLSessionConfiguration class])' to only call "
              @"this method if the user is running iOS7+/OSX9+.", NSStringFromSelector(_cmd));
        return NO;
    }
}

@end
