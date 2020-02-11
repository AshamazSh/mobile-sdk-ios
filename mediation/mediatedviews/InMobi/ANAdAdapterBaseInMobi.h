/*   Copyright 2015 APPNEXUS INC
 
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

#import <InMobiSDK/IMSdk.h>
#import <InMobiSDK/IMRequestStatus.h>



/**
 The InMobi app ID should be set before ads are loaded. All invocations of the InMobi mediation adapters
 will fail to return an ad if the ID is not set.
 */
@interface ANAdAdapterBaseInMobi : NSObject

+ (void)setInMobiAppID:(NSString *)appId;

@end
