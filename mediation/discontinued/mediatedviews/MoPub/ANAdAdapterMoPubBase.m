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

#import "ANAdAdapterMoPubBase.h"

@implementation ANAdAdapterMoPubBase

@synthesize delegate;

- (NSString *)keywordsFromTargetingParameters:(ANTargetingParameters *)targetingParameters {
    NSMutableArray *keywordArray = [[NSMutableArray alloc] init];
    
    ANGender gender = targetingParameters.gender;
    switch (gender) {
        case ANGenderMale:
            [keywordArray addObject:@"m_gender:male"];
            break;
        case ANGenderFemale:
            [keywordArray addObject:@"m_gender:female"];
            break;
        default:
            break;
    }
    
    if ([targetingParameters age]) {
        [keywordArray addObject:[NSString stringWithFormat:@"m_age:%@", targetingParameters.age]];
    }
    
    [targetingParameters.customKeywords enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [keywordArray addObject:[NSString stringWithFormat:@"%@:%@", key, obj]];
    }];
    
    return [keywordArray componentsJoinedByString:@","];
}

- (CLLocation *)locationFromTargetingParameters:(ANTargetingParameters *)targetingParameters {
    ANLocation *location = targetingParameters.location;
    if (location) {
        CLLocation *mpLoc = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(location.latitude, location.longitude)
                                                          altitude:0
                                                horizontalAccuracy:location.horizontalAccuracy
                                                  verticalAccuracy:0
                                                         timestamp:location.timestamp];
        return mpLoc;
    }
    return nil;
}

@end
