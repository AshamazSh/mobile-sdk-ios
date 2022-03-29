/*   Copyright 2022 APPNEXUS INC
 
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

#import <Foundation/Foundation.h>
/*
 *  Supported Predefined Sources
 * */
typedef NS_ENUM(NSUInteger, ANUserIdSource)  {
    ANUserIdSourceLiveRamp,
    ANUserIdSourceNetId,
    ANUserIdSourceCriteo,
    ANUserIdSourceTheTradeDesk,
    ANUserIdSourceUID2
};



/**
 Defines the User Id Object from an External Thrid Party Source
 */
@interface ANUserId : NSObject

/**
 Source of the  User Id
 */
@property (nonatomic, readwrite, strong, nonnull) NSString *source;

/**
 The User Id String
 */
@property (nonatomic, readwrite, strong, nonnull) NSString *userId;


- (nullable instancetype)initWithANUserIdSource:(ANUserIdSource)source userId:(nonnull NSString *)userId;

- (nullable instancetype)initWithStringSource:(nonnull NSString *)source userId:(nonnull NSString *)userId;

@end

