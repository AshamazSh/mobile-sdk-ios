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

#import <objc/runtime.h>

#import "ANUniversalAdFetcher+ANTest.h"
#import "ANTestGlobal.h"



#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation ANUniversalAdFetcher (ANTest)
#pragma clang diagnostic pop

@dynamic adView;


+ (void)load
{
TESTTRACE();
    NSBlockOperation  *operation  = [NSBlockOperation blockOperationWithBlock:
            ^{
                [[self class] exchangeOriginalSelector:@selector(fireResponseURL:reason:adObject:auctionID:)
                                          withSelector:@selector(test_fireResponseURL:reason:adObject:auctionID:)];
            } ];

    [operation start];
}

+ (void)exchangeOriginalSelector: (SEL)originalSelector
                    withSelector: (SEL)swizzledSelector
{
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)test_fireResponseURL: (NSString *)resultCBString
                      reason: (ANAdResponseCode)reason
                    adObject: (id)adObject
                   auctionID: (NSString *)auctionID
{
TESTTRACE();
    NSDictionary  *userInfo  = @{kANUniversalAdFetcherFireResponseURLRequestedReason:@(reason)};

    [[NSNotificationCenter defaultCenter] postNotificationName:kANUniversalAdFetcherFireResponseURLRequestedNotification
                                                        object:self
                                                      userInfo:userInfo];
    [self test_fireResponseURL: resultCBString
                        reason: reason
                      adObject: adObject
                     auctionID: auctionID];
}

@end
