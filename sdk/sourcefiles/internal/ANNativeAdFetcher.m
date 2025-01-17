/*   Copyright 2019 APPNEXUS INC
 
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

#import "ANNativeAdFetcher.h"
#import "ANUniversalTagRequestBuilder.h"
#import "ANSDKSettings+PrivateMethods.h"
#import "ANLogging.h"
#import "ANAdResponseInfo.h"
#import "ANStandardAd.h"
#import "ANRTBVideoAd.h"
#import "ANCSMVideoAd.h"
#import "ANSSMStandardAd.h"
#import "ANNativeStandardAdResponse.h"
#import "ANMediatedAd.h"
#import "ANAdConstants.h"

#if !APPNEXUS_NATIVE_MACOS_SDK
    #import "ANNativeMediatedAdController.h"
    #import "ANCSRAd.h"
    #import "ANCSRNativeAdController.h"
#endif

              
#import "ANTrackerInfo.h"
#import "ANTrackerManager.h"
#import "NSTimer+ANCategory.h"

@interface ANNativeAdFetcher()
#if !APPNEXUS_NATIVE_MACOS_SDK
@property (nonatomic, readwrite, strong)  ANNativeMediatedAdController      *nativeMediationController;
@property (nonatomic, readwrite, strong)  ANCSRNativeAdController      *nativeBannerMediatedAdController;
#endif

@end

@implementation ANNativeAdFetcher

-(nonnull instancetype) initWithDelegate:(nonnull id)delegate
{
    if (self = [self init]) {
        self.delegate = delegate;
    }
    return self;
}

- (void)clearMediationController {
    /*
     * Ad fetcher gets cleared, in the event the mediation controller lives beyond the ad fetcher.  The controller maintains a weak reference to the
     * ad fetcher delegate so that messages to the delegate can proceed uninterrupted.  Currently, the controller will only live on if it is still
     * displaying inside a banner ad view (in which case it will live on until the individual ad is destroyed).
     */
    
#if !APPNEXUS_NATIVE_MACOS_SDK
    self.nativeMediationController = nil;
#endif
    
}



#pragma mark - UT ad response processing methods
- (void)finishRequestWithError:(NSError *)error andAdResponseInfo:(ANAdResponseInfo *)adResponseInfo
{
    self.isFetcherLoading = NO;
    ANLogInfo(@"No ad received. Error: %@", error.localizedDescription);
    ANAdFetcherResponse *response = [ANAdFetcherResponse responseWithError:error];
    response.adResponseInfo = adResponseInfo;
    [self processFinalResponse:response];
}

- (void)processFinalResponse:(ANAdFetcherResponse *)response
{
    self.ads = nil;
    self.isFetcherLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didFinishRequestWithResponse:)]) {
        [self.delegate didFinishRequestWithResponse:response];
    }
}

//NB  continueWaterfall is co-functional the ad handler methods.
//    The loop of the waterfall lifecycle is managed by methods calling one another
//      until a valid ad object is found OR when the waterfall runs out.
//
- (void)continueWaterfall:(ANAdResponseCode *)reason
{
    // stop waterfall if delegate reference (adview) was lost
    if (!self.delegate) {
        self.isFetcherLoading = NO;
        return;
    }
    
    BOOL adsLeft = (self.ads.count > 0);
    
    if (!adsLeft) {
        if (self.noAdUrl) {
             ANLogDebug(@"(no_ad_url, %@)", self.noAdUrl);
             [ANTrackerManager fireTrackerURL:self.noAdUrl];
         }
        [self finishRequestWithResponseCode:reason];
        return;
    }
    
    
    //
    id nextAd = [self.ads firstObject];
    [self.ads removeObjectAtIndex:0];
    
    self.adObjectHandler = nextAd;
    
#if !APPNEXUS_NATIVE_MACOS_SDK
    // CSR need to be checked first as It's inheriting ANMediatedAd
    if ([nextAd isKindOfClass:[ANCSRAd class]] ){
        [self handleCSRNativeAd:nextAd];
    }else if ( [nextAd isKindOfClass:[ANMediatedAd class]] ) {
        [self handleCSMSDKMediatedAd:nextAd];
    }else if ( [nextAd isKindOfClass:[ANNativeStandardAdResponse class]] ) {
        [self handleNativeStandardAd:nextAd];
    }else {
        ANLogError(@"Implementation error: Unspported ad in native ads waterfall.  (class=%@)", [nextAd class]);
        [self continueWaterfall:ANAdResponseCode.UNABLE_TO_FILL]; // skip this ad an jump to next ad
    }
#else
    if ( [nextAd isKindOfClass:[ANNativeStandardAdResponse class]] ) {
        [self handleNativeStandardAd:nextAd];
    }
#endif
  
}


-(void) stopAdLoad {
    [super stopAdLoad];
}


- (void)startAutoRefreshTimer
{
    // Implemented only by ANAdFetcher
}

- (void)restartAutoRefreshTimer
{
    // Implemented only by ANAdFetcher
}




#pragma mark - Ad handlers.
#if !APPNEXUS_NATIVE_MACOS_SDK

- (void)handleCSRNativeAd:(ANCSRAd *)csrAd
{
    self.nativeBannerMediatedAdController = [ANCSRNativeAdController initCSRAd: csrAd
                                                                                withFetcher: self
                                                                          adRequestDelegate: self.delegate];
}

- (void)handleCSMSDKMediatedAd:(ANMediatedAd *)mediatedAd
{
    if (mediatedAd.isAdTypeNative)
    {
        self.nativeMediationController = [ANNativeMediatedAdController initMediatedAd: mediatedAd
                                                                          withFetcher: self
                                                                    adRequestDelegate: self.delegate ];
    } else {
        // TODO: should do something here
    }
}
#endif

- (void)handleNativeStandardAd:(ANNativeStandardAdResponse *)nativeStandardAd
{
    
    ANAdFetcherResponse  *fetcherResponse  = [ANAdFetcherResponse responseWithAdObject:nativeStandardAd andAdObjectHandler:nil];
    [self processFinalResponse:fetcherResponse];
}

@end
