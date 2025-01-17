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

#import "ANNativeAdRequest.h"
#import "ANNativeAdFetcher.h"
#import "ANGlobal.h"
#import "ANLogging.h"
#import "ANAdConstants.h"

#if !APPNEXUS_NATIVE_MACOS_SDK
#import "ANOMIDImplementation.h"
#import "ANNativeMediatedAdResponse.h"
#endif
#import "ANNativeAdImageCache.h"
#import "ANMultiAdRequest+PrivateMethods.h"
#import "ANHTTPNetworkSession.h"
#import "ANNativeAdResponse+PrivateMethods.h"
#import "XandrImage.h"



@interface ANNativeAdRequest() <ANNativeAdFetcherDelegate>

@property (nonatomic, readwrite, strong) ANNativeAdFetcher *adFetcher;

@property (nonatomic, strong)     NSMutableSet<NSValue *>  *allowedAdSizes;
@property (nonatomic, readwrite)  BOOL                      allowSmallerSizes;
@property (nonatomic, readwrite, weak, nullable)  ANMultiAdRequest  *marManager;


@property (nonatomic, readwrite, strong, nonnull)  NSString  *utRequestUUIDString;

@end




@implementation ANNativeAdRequest

#pragma mark - ANNativeAdRequestProtocol properties.

// ANNativeAdRequestProtocol properties.
//
@synthesize  placementId     = __placementId;
@synthesize  publisherId     = __publisherId;
@synthesize  memberId        = __memberId;
@synthesize  inventoryCode   = __invCode;
@synthesize  location        = __location;
@synthesize  reserve         = __reserve;
@synthesize  age             = __age;
@synthesize  gender          = __gender;
@synthesize  customKeywords  = __customKeywords;
@synthesize  forceCreativeId     = __forceCreativeId;
@synthesize  rendererId             = _rendererId;
@synthesize  extInvCode             = __extInvCode;
@synthesize  trafficSourceCode      = __trafficSourceCode;
@synthesize  shouldServePublicServiceAnnouncements  = __shouldServePublicServiceAnnouncements;




#pragma mark - Lifecycle.

- (instancetype)init
{
    self = [super init];
    if (!self)  { return nil; }


    //
    self.customKeywords = [[NSMutableDictionary alloc] init];

    [self setupSizeParametersAs1x1];
#if !APPNEXUS_NATIVE_MACOS_SDK
    [[ANOMIDImplementation sharedInstance] activateOMIDandCreatePartner];
#endif

    
    self.utRequestUUIDString = ANUUID();
    return self;
}

- (void) setupSizeParametersAs1x1
{
#if !APPNEXUS_NATIVE_MACOS_SDK
    self.allowedAdSizes     = [NSMutableSet setWithObject:[NSValue valueWithCGSize:kANAdSize1x1]];
#else
    self.allowedAdSizes     = [NSMutableSet setWithObject:[NSValue valueWithSize:kANAdSize1x1]];
#endif
    self.allowSmallerSizes  = NO;
    _rendererId             = 0;
}

- (void)loadAd
{
    if (!self.delegate) {
        ANLogError(@"ANNativeAdRequestDelegate must be set on ANNativeAdRequest in order for an ad to begin loading");
        return;
    }
    [self createAdFetcher];
    [self.adFetcher requestAd];
}

/**
 *  This method provides a single point of entry for the MAR object to pass tag content received in the UT Request to the fetcher defined by the adunit.
 *  Adding this public method which is used only for an internal process is more desirable than making the adFetcher property public.
 */
- (void)ingestAdResponseTag: (NSDictionary<NSString *, id> *)tag
{
    if (!self.delegate) {
        ANLogError(@"ANNativeAdRequestDelegate must be set on ANNativeAdRequest in order for an ad to be ingested.");
        return;
    }

    [self createAdFetcher];

    [self.adFetcher prepareForWaterfallWithAdServerResponseTag:tag];
}

- (void)createAdFetcher
{
    if (self.marManager) {
        self.adFetcher = [[ANNativeAdFetcher alloc] initWithDelegate:self andAdUnitMultiAdRequestManager:self.marManager];
    } else {
        self.adFetcher  = [[ANNativeAdFetcher alloc] initWithDelegate:self];
    }
}




#pragma mark - ANNativeAdFetcherDelegate.

-(void)didFinishRequestWithResponse: (nonnull ANAdFetcherResponse *)response
{
    NSError  *error  = nil;

    if (!response.isSuccessful) {
        error = response.error;

    } else if (! [response.adObject isKindOfClass:[ANNativeAdResponse class]]) {
        error = ANError(@"native_request_invalid_response", ANAdResponseCode.BAD_FORMAT.code);
    }

    if (error) {
        if ([self.delegate respondsToSelector:@selector(adRequest:didFailToLoadWithError:withAdResponseInfo:)]) {
            [self.delegate adRequest:self didFailToLoadWithError:error withAdResponseInfo:response.adResponseInfo];
        }

        return;
    }


    //
    __weak ANNativeAdRequest  *weakSelf        = self;
    ANNativeAdResponse        *nativeResponse  = (ANNativeAdResponse *)response.adObject;
    
    // register AdWillExpire
    [nativeResponse registerAdWillExpire];
        
    // In case of Mediation
    if (nativeResponse.adResponseInfo == nil) {
        ANAdResponseInfo *adResponseInfo  = (ANAdResponseInfo *) [ANGlobal valueOfGetterProperty:kANAdResponseInfo forObject:response.adObjectHandler];
        if (adResponseInfo) {
            [self setAdResponseInfo:adResponseInfo onObject:nativeResponse forKeyPath:kANAdResponseInfo];
        }
    }

    //
    dispatch_queue_t  backgroundQueue  = dispatch_queue_create(__PRETTY_FUNCTION__, DISPATCH_QUEUE_SERIAL);

    dispatch_async(backgroundQueue,
    ^{
        __strong ANNativeAdRequest  *strongSelf  = weakSelf;

        if (!strongSelf) {
           ANLogError(@"FAILED to access strongSelf.");
           return;
        }

        //
        dispatch_semaphore_t  semaphoreMainImage  = nil;
        dispatch_semaphore_t  semaphoreIconImage  = nil;

        
        if (self.shouldLoadMainImage && [nativeResponse respondsToSelector:@selector(setMainImage:)])
        {
            semaphoreMainImage = [self setImageInBackgroundForImageURL: nativeResponse.mainImageURL
                                                              onObject: nativeResponse
                                                            forKeyPath: @"mainImage" ];
        }

        if (self.shouldLoadIconImage && [nativeResponse respondsToSelector:@selector(setIconImage:)])
        {
            semaphoreIconImage = [self setImageInBackgroundForImageURL: nativeResponse.iconImageURL
                                                              onObject: nativeResponse
                                                            forKeyPath: @"iconImage" ];
        }

        if (semaphoreMainImage)  {
            dispatch_semaphore_wait(semaphoreMainImage, DISPATCH_TIME_FOREVER);
        }

        if (semaphoreIconImage)  {
            dispatch_semaphore_wait(semaphoreIconImage, DISPATCH_TIME_FOREVER);
        }


        dispatch_async(dispatch_get_main_queue(), ^{
            ANLogDebug(@"...END NSURL sessions.");

            if ([strongSelf.delegate respondsToSelector:@selector(adRequest:didReceiveResponse:)]) {
                [strongSelf.delegate adRequest:strongSelf didReceiveResponse:nativeResponse];
            }
        });
    });
}

- (NSArray<NSValue *> *)adAllowedMediaTypes
{
    return  @[ @(ANAllowedMediaTypeNative) ];
}

-(NSInteger) nativeAdRendererId{
    return _rendererId;
}

- (NSDictionary *) internalDelegateUniversalTagSizeParameters
{
    NSMutableDictionary  *delegateReturnDictionary  = [[NSMutableDictionary alloc] init];
 
#if !APPNEXUS_NATIVE_MACOS_SDK
    [delegateReturnDictionary setObject:[NSValue valueWithCGSize:kANAdSize1x1]  forKey:ANInternalDelgateTagKeyPrimarySize];
#else
    [delegateReturnDictionary setObject:[NSValue valueWithSize:kANAdSize1x1]  forKey:ANInternalDelgateTagKeyPrimarySize];
#endif
    [delegateReturnDictionary setObject:self.allowedAdSizes                     forKey:ANInternalDelegateTagKeySizes];
    [delegateReturnDictionary setObject:@(self.allowSmallerSizes)               forKey:ANInternalDelegateTagKeyAllowSmallerSizes];

  
    return  delegateReturnDictionary;
}

- (NSString *)internalGetUTRequestUUIDString
{
    return  self.utRequestUUIDString;
}

- (void)internalUTRequestUUIDStringReset
{
    self.utRequestUUIDString = ANUUID();
}


// NB  Some duplication between ANNativeAd* and the other entry points is inevitable because ANNativeAd* does not inherit from ANAdView.
//
#pragma mark - ANUniversalAdFetcherFoundationDelegate helper methods.


- (void)setAdResponseInfo:(ANAdResponseInfo *)adResponseInfo
             onObject:(id)object forKeyPath:(NSString *)keyPath
{
    [object setValue:adResponseInfo forKeyPath:keyPath];
}

// RETURN:  dispatch_semaphore_t    For first time image requests.
//          nil                     When image is cached  -OR-  if imageURL is undefined.
//
// If semaphore is defined, call dispatch_semaphore_wait(semaphor, DISPATCH_TIME_FOREVER) to wait for this background task
//   before continuing in the calling method.
// Wait period is limited by NSURLRequest with timeoutInterval of kAppNexusNativeAdImageDownloadTimeoutInterval.
//

- (dispatch_semaphore_t) setImageInBackgroundForImageURL: (NSURL *)imageURL
                                                onObject: (id)object
                                              forKeyPath: (NSString *)keyPath
{
    if (!imageURL)  { return nil; }

   
    XandrImage *cachedImage = [ANNativeAdImageCache imageForKey:imageURL];
    
    if (cachedImage) {
        [object setValue:cachedImage forKeyPath:keyPath];
        return  nil;
    }

    //
    dispatch_semaphore_t  semaphore  = dispatch_semaphore_create(0);

    NSURLRequest  *request  = [NSURLRequest requestWithURL: imageURL
                                               cachePolicy: NSURLRequestReloadIgnoringLocalCacheData
                                           timeoutInterval: kAppNexusNativeAdImageDownloadTimeoutInterval];
    
    
    [ANHTTPNetworkSession startTaskWithHttpRequest:request responseHandler:^(NSData * _Nonnull data, NSHTTPURLResponse * _Nonnull response) {
        
        XandrImage  *image  = [XandrImage getImageWithData:data];
        if (image) {
            [ANNativeAdImageCache setImage:image forKey:imageURL];
            [object setValue:image forKeyPath:keyPath];
        }
        dispatch_semaphore_signal(semaphore);
        
    } errorHandler:^(NSError * _Nonnull error) {
        ANLogError(@"Error downloading image: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
    //
    return  semaphore;
}



#pragma mark - ANNativeAdRequestProtocol methods.

- (void)setExtInvCode:(nullable NSString *)extInvCode{
    extInvCode = ANConvertToNSString(extInvCode);
    if ([extInvCode length] < 1) {
        ANLogError(@"Could not set extInvCode to non-string value");
        return;
    }
    if (extInvCode != __extInvCode) {
        ANLogDebug(@"Setting extInvCode to %@", extInvCode);
        __extInvCode = extInvCode;
    }
}

- (void)setTrafficSourceCode:(nullable NSString *)trafficSourceCode{
    trafficSourceCode = ANConvertToNSString(trafficSourceCode);
    if ([trafficSourceCode length] < 1) {
        ANLogError(@"Could not set trafficSourceCode to non-string value");
        return;
    }
    if (trafficSourceCode != __trafficSourceCode) {
        ANLogDebug(@"Setting trafficSourceCode to %@", __trafficSourceCode);
        __trafficSourceCode = trafficSourceCode;
    }
}
- (void)setForceCreativeId:(NSInteger)forceCreativeId {
    if (forceCreativeId <= 0) {
        ANLogError(@"Could not set forceCreativeId to %ld", (long)forceCreativeId);
        return;
    }
    if (forceCreativeId != __forceCreativeId) {
        ANLogDebug(@"Setting forceCreativeId to %ld", (long)forceCreativeId);
        __forceCreativeId = forceCreativeId;
    }
}

- (void)setPlacementId:(nullable NSString *)placementId {
    placementId = ANConvertToNSString(placementId);
    if ([placementId length] < 1) {
        ANLogError(@"Could not set placementId to non-string value");
        return;
    }
    if (placementId != __placementId) {
        ANLogDebug(@"Setting placementId to %@", placementId);
        __placementId = placementId;
    }
}

- (void)setPublisherId:(NSInteger)newPublisherId
{
    if ((newPublisherId > 0) && self.marManager)
    {
        if (self.marManager.publisherId != newPublisherId) {
            ANLogError(@"Arguments ignored because newPublisherID (%@) is not equal to publisherID used in Multi-Ad Request.", @(newPublisherId));
            return;
        }
    }

    ANLogDebug(@"Setting publisher ID to %d", (int) newPublisherId);
    __publisherId = newPublisherId;
}

- (void)setInventoryCode:(nullable NSString *)newInvCode memberId:(NSInteger)newMemberId
{
    if ((newMemberId > 0) && self.marManager)
    {
        if (self.marManager.memberId != newMemberId) {
            ANLogError(@"Arguments ignored because newMemberId (%@) is not equal to memberID used in Multi-Ad Request.", @(newMemberId));
            return;
        }
    }

    //
    newInvCode = ANConvertToNSString(newInvCode);
    if (newInvCode && newInvCode != __invCode) {
        ANLogDebug(@"Setting inventory code to %@", newInvCode);
        __invCode = newInvCode;
    }
    if (newMemberId > 0 && newMemberId != __memberId) {
        ANLogDebug(@"Setting member id to %d", (int) newMemberId);
        __memberId = newMemberId;
    }
}

- (void)setLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude
                      timestamp:(nullable NSDate *)timestamp horizontalAccuracy:(CGFloat)horizontalAccuracy {
    self.location = [ANLocation getLocationWithLatitude:latitude
                                              longitude:longitude
                                              timestamp:timestamp
                                     horizontalAccuracy:horizontalAccuracy];
}

- (void)setLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude
                      timestamp:(nullable NSDate *)timestamp horizontalAccuracy:(CGFloat)horizontalAccuracy
                      precision:(NSInteger)precision {
    self.location = [ANLocation getLocationWithLatitude:latitude
                                              longitude:longitude
                                              timestamp:timestamp
                                     horizontalAccuracy:horizontalAccuracy
                                              precision:precision];
}


- (void)addCustomKeywordWithKey:(nonnull NSString *)key
                          value:(nonnull NSString *)value
{
    if (([key length] < 1) || !value) {
        return;
    }
    
    if(self.customKeywords[key] != nil){
        NSMutableArray *valueArray = (NSMutableArray *)[self.customKeywords[key] mutableCopy];
        if (![valueArray containsObject:value]) {
            [valueArray addObject:value];
        }
        self.customKeywords[key] = [valueArray copy];
    } else {
        self.customKeywords[key] = @[value];
    }
}

- (void)removeCustomKeywordWithKey:(nonnull NSString *)key
{
    if (([key length] < 1)) {
        return;
    }
    
    [self.customKeywords removeObjectForKey:key];
}

- (void)clearCustomKeywords
{
    [self.customKeywords removeAllObjects];
}

@end

