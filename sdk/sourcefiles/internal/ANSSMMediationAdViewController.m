/*   Copyright 2013 APPNEXUS INC
 
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

#import "ANSSMMediationAdViewController.h"

#import "ANBannerAdView.h"
#import "ANGlobal.h"
#import "ANInterstitialAd.h"
#import "ANLogging.h"
#import "ANSSMStandardAd.h"
#import "NSString+ANCategory.h"
#import "ANMRAIDContainerView.h"
#import "ANSDKSettings+PrivateMethods.h"
#import "NSObject+ANCategory.h"
#import "ANHTTPNetworkSession.h"


@interface ANSSMMediationAdViewController () <ANAdWebViewControllerLoadingDelegate>

@property (nonatomic, readwrite, assign)  BOOL                               hasSucceeded;
@property (nonatomic, readwrite, assign)  BOOL                               hasFailed;
@property (nonatomic, readwrite, assign)  BOOL                               timeoutCanceled;
@property (nonatomic, readwrite, weak)    id<ANAdFetcherDelegate>   adViewDelegate;
@property (nonatomic, readwrite, strong)  ANSSMStandardAd                   *ssmMediatedAd;
@property (nonatomic, readwrite, strong)  NSURL                             *ssmHandlerURL;
@property (nonatomic, readwrite, strong) NSURLConnection                    *connection;
@property (nonatomic, readwrite, getter = isLoading) BOOL loading;
@property (nonatomic, readwrite, strong)  ANMRAIDContainerView              *ssmAdView;

// variables for measuring latency.
@property (nonatomic, readwrite, assign)  NSTimeInterval  latencyStart;
@property (nonatomic, readwrite, assign)  NSTimeInterval  latencyStop;

@end



@implementation ANSSMMediationAdViewController

#pragma mark - Lifecycle.

+ (ANSSMMediationAdViewController *)initMediatedAd:(ANSSMStandardAd *)ssmMediatedAd
                                       withFetcher:(ANAdFetcher *)fetcher
                                    adViewDelegate:(id<ANAdFetcherDelegate>)adViewDelegate
{
    ANSSMMediationAdViewController *controller = [[ANSSMMediationAdViewController alloc] init];
    controller.adFetcher = fetcher;
    controller.adViewDelegate = adViewDelegate;
    
    if ([controller requestForAd:ssmMediatedAd]) {
        return controller;
    } else {
        
        // Just return nil here requestForAd will send the AdFailed and waterfall will continue
        return nil;
    }
}

- (BOOL)requestForAd:(ANSSMStandardAd *)ad {
    // variables to pass into the failure handler if necessary
    NSString *errorInfo = nil;
    ANAdResponseCode *errorCode = ANAdResponseCode.DEFAULT;
    
    // check that the ad is non-nil
    if ((!ad) || (!ad.urlString)) {
        errorInfo = @"null mediated ad object";
        errorCode = ANAdResponseCode.UNABLE_TO_FILL;
        [self handleFailure:errorCode errorInfo:errorInfo];
        return NO;
    }else{
        [self markLatencyStart];
        self.ssmMediatedAd = ad;
        [self startTimeout];
        self.ssmHandlerURL = [NSURL URLWithString:ad.urlString];
        ANLogDebug(@"requesting SSM mediated Ad from URL %@", self.ssmHandlerURL);
        
        NSURLRequest *request     = ANBasicRequestWithURL(self.ssmHandlerURL);
        
        __weak __typeof__(self) weakSelf = self;
        [ANHTTPNetworkSession startTaskWithHttpRequest:request responseHandler:^(NSData * _Nonnull data, NSHTTPURLResponse * _Nonnull response) {
            __typeof__(self) strongSelf = weakSelf;
            NSString *responseString = [[NSString alloc] initWithData:data
                                                             encoding:NSUTF8StringEncoding];
            ANLogDebug(@"Response JSON %@", responseString);
            ANLogDebug(@"SSM Received response: %@", response);
            
            [strongSelf didReceiveAd:responseString];
            
        } errorHandler:^(NSError * _Nonnull error) {
            __typeof__(self) strongSelf = weakSelf;
            [strongSelf handleFailure:ANAdResponseCode.NETWORK_ERROR errorInfo:@"connection_failed"];
            
        }];
        
        return YES;
    }
    
}



- (void)handleFailure:(ANAdResponseCode *)errorCode
            errorInfo:(NSString *)errorInfo
{
    
    ANLogError(@"ssm_mediation_failure %@", (nil == errorInfo) ? @"" : errorInfo);
    
    [self didFailToReceiveAd:errorCode];
}




- (void)clearAdapter {
    self.hasSucceeded = NO;
    self.hasFailed = YES;
    self.adFetcher = nil;
    self.adViewDelegate = nil;
    self.ssmMediatedAd = nil;
    [self cancelTimeout];
    ANLogInfo(@"mediation_finish");
}




#pragma mark - helper methods

- (BOOL)checkIfHasResponded {
    // we received a callback from mediation adaptor, cancel timeout
    [self cancelTimeout];
    // don't succeed or fail more than once per mediated ad
    return (self.hasSucceeded || self.hasFailed);
}

- (void)didReceiveAd:(NSString *)adContent
{
    if ([self checkIfHasResponded])  { return; }
    
    if (!adContent || !(adContent.length>0)) {
        [self handleFailure:ANAdResponseCode.INTERNAL_ERROR errorInfo:@"Received Empty SSM response from server"];
        return;
    }
    
    self.hasSucceeded = YES;
    [self markLatencyStop];
    self.ssmMediatedAd.content = adContent;
    
    ANLogDebug(@"received an SSM ad");
    
    
    if (self.ssmAdView) {
        self.ssmAdView.loadingDelegate = nil;
    }
    
    
    CGSize sizeofWebView = [self.adFetcher getWebViewSizeForCreativeWidth:self.ssmMediatedAd.width
                                                                andHeight:self.ssmMediatedAd.height];
    
    self.ssmAdView = [[ANMRAIDContainerView alloc] initWithSize:sizeofWebView
                                                           HTML:self.ssmMediatedAd.content
                                                 webViewBaseURL:[NSURL URLWithString:[[[ANSDKSettings sharedInstance] baseUrlConfig] webViewBaseUrl]]];
    self.ssmAdView.loadingDelegate = self;
    // Allow ANJAM events to always be passed to the ANAdView
    self.ssmAdView.webViewController.adViewANJAMInternalDelegate = self.adViewDelegate;
    
    //fire impressionURLS much earlier in the lifecycle
    [self.adFetcher checkifBeginToRenderAndFireImpressionTracker:self.ssmMediatedAd];
    
}

- (void)didFailToReceiveAd:(ANAdResponseCode *)errorCode {
    if ([self checkIfHasResponded]) return;
    [self markLatencyStop];
    self.hasFailed = YES;
    [self finish:errorCode withAdObject:nil];
}


- (void)finish: (ANAdResponseCode *)errorCode
  withAdObject: (id)adObject
{
    // use queue to force return
    [self runInBlock:^(void) {
        ANAdFetcher *fetcher = self.adFetcher;
        
        NSString *responseURL = [self.ssmMediatedAd.responseURL an_responseTrackerReasonCode: (int)errorCode
                                                                                     latency: [self getLatency] * 1000 ];
        
        // fireResponseURL will clear the adapter if fetcher exists
        if (!fetcher) {
            [self clearAdapter];
        }
        [fetcher fireResponseURL:responseURL reason:errorCode adObject:adObject];
    }];
}



#pragma mark - ANAdWebViewControllerLoadingDelegate.

- (void)didCompleteFirstLoadFromWebViewController:(ANAdWebViewController *)controller
{
    if (self.ssmAdView.webViewController == controller) {
        [self finish:ANAdResponseCode.SUCCESS withAdObject:self.ssmAdView];
    }
}



#pragma mark - Timeout handler

- (void)startTimeout {
    if (self.timeoutCanceled) return;
    __weak ANSSMMediationAdViewController *weakSelf = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 self.ssmMediatedAd.networkTimeout * NSEC_PER_MSEC),
                   dispatch_get_main_queue(), ^{
                       ANSSMMediationAdViewController *strongSelf = weakSelf;
                       if (!strongSelf || strongSelf.timeoutCanceled) return;
                       [strongSelf handleFailure:ANAdResponseCode.INTERNAL_ERROR errorInfo:@"mediation_timeout"];
                   });
    
}

- (void)cancelTimeout {
    self.timeoutCanceled = YES;
}



# pragma mark - Latency Measurement

/**
 * Should be called immediately after mediated SDK returns
 * from `requestAd` call.
 */
- (void)markLatencyStart {
    self.latencyStart = [NSDate timeIntervalSinceReferenceDate];
}

/**
 * Should be called immediately after mediated SDK
 * calls either of `onAdLoaded` or `onAdFailed`.
 */
- (void)markLatencyStop {
    self.latencyStop = [NSDate timeIntervalSinceReferenceDate];
}

/**
 * The latency of the call to the mediated SDK.
 */
- (NSTimeInterval)getLatency {
    if ((self.latencyStart > 0) && (self.latencyStop > 0)) {
        return (self.latencyStop - self.latencyStart);
    }
    // return -1 if invalid.
    return -1;
}


- (void)dealloc {
    [self clearAdapter];
}

@end
