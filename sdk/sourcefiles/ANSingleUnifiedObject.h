//
//  ANSingleUnifiedObject.h
//  AppNexusSDK
//
//  Created by Akash Verma on 13/09/19.
//  Copyright © 2019 AppNexus. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ANSingleUnifiedObject : NSObject
/**
 An AppNexus creativeID for the current creative that is displayed
 */
@property (nonatomic, readonly, strong, nullable) NSString *creativeId;
- (void)anParseResponse:(NSDictionary *)jsonDic;

@end

NS_ASSUME_NONNULL_END
