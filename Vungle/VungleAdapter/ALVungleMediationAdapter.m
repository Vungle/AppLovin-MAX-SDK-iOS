//
//  ALVungleMediationAdapter.m
//  Adapters
//
//  Created by Christopher Cong on 10/19/18.
//  Copyright © 2018 AppLovin. All rights reserved.
//

#import "ALVungleMediationAdapter.h"
#import <VungleAds/VungleAds.h>

#define ADAPTER_VERSION @"7.0.0.0"

int const kALSdkVersionCode =  11020199;
int const kALSdkVersionNeeded = 6150000;
int const kALErrorCode =  -4205;

@interface ALVungleMediationInterstitialAdapterRouter : NSObject<VungleInterstitialDelegate>
@property (nonatomic, weak) ALVungleMediationAdapter *parentAdapter;
@property (nonatomic, strong) id<MAInterstitialAdapterDelegate> interstitialAdDelegate;
- (nonnull instancetype)initVungleInterstitialAdDelegate:(id<MAInterstitialAdapterDelegate>)interstitialAdDelegate parentAdapter:(ALVungleMediationAdapter *)parentAdapter;
@end

@interface ALVungleMediationRewardedAdapterRouter : NSObject<VungleRewardedDelegate>
@property (nonatomic, weak) ALVungleMediationAdapter *parentAdapter;
@property (nonatomic, strong) id<MARewardedAdapterDelegate> rewardedAdDelegate;
- (nonnull instancetype)initVungleRewardedAdDelegate:(id<MARewardedAdapterDelegate>)rewardedAdDelegate parentAdapter:(ALVungleMediationAdapter *)parentAdapter;
@end

@interface ALVungleMediationAdViewAdapterRouter : NSObject<VungleBannerDelegate>
@property (nonatomic, weak) ALVungleMediationAdapter *parentAdapter;
@property (nonatomic, strong) UIView *adView;
@property (nonatomic, strong) VungleBanner *vungleBannerAd;
@property (nonatomic, strong) MAAdFormat *adFormat;
@property (nonatomic, strong) id<MAAdViewAdapterDelegate> adViewAdDelegate;
@property (nonatomic, strong) id<MAAdapterResponseParameters> parameters;
- (nonnull instancetype)initVungleAdViewAdDelegate:(id<MAAdViewAdapterDelegate>)adViewAdDelegate parentAdapter:(ALVungleMediationAdapter *)parentAdapter parameters:(id<MAAdapterResponseParameters>)parameters adFormat:(MAAdFormat *)adFormat;
- (void)loadAdView:(NSString *)placementIdentifier;
- (void)destroy;
@end

@interface ALVungleMediationNativeAdAdapter : NSObject<VungleNativeDelegate>
@property (nonatomic, strong) VungleNative *vungleNativeAd;
@property (nonatomic, strong) id<MANativeAdAdapterDelegate> nativeAdDelegate;
@property (nonatomic, strong) id<MAAdapterResponseParameters> parameters;
- (nonnull instancetype)initVungleNativeAdDelegate:(id<MANativeAdAdapterDelegate>)nativeAdDelegate parameters:(id<MAAdapterResponseParameters>)parameters;
- (void)requestNativeAd:(NSString *)placementIdentifier;
- (void)unregisterNativeAd;
- (void)destroy;
@end

@interface MAVungleNativeAd : MANativeAd
@property (nonatomic, weak) ALVungleMediationNativeAdAdapter *parentAdapter;
- (instancetype)initWithParentAdapter:(ALVungleMediationNativeAdAdapter *)parentAdapter builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock;
@end

@interface ALVungleMediationAdapter()
@property (nonatomic, strong) VungleInterstitial *vungleInterstitialAd;
@property (nonatomic, strong) VungleRewarded *vungleRewardedVideoAd;

@property (nonatomic, strong) ALVungleMediationInterstitialAdapterRouter *interstitialRouter;
@property (nonatomic, strong) ALVungleMediationRewardedAdapterRouter *rewardedRouter;
@property (nonatomic, strong) ALVungleMediationAdViewAdapterRouter *bannerRouter;
@property (nonatomic, strong) ALVungleMediationNativeAdAdapter *nativeAdRouter;

- (void)updateUserPrivacySettingsForParameters:(id<MAAdapterParameters>)parameters consentDialogState:(ALConsentDialogState)consentDialogState;
- (nullable NSNumber *)privacySettingForSelector:(SEL)selector fromParameters:(id<MAAdapterParameters>)parameters;
@end

@implementation ALVungleMediationAdapter

static ALAtomicBoolean              *ALVungleInitialized;
static MAAdapterInitializationStatus ALVungleIntializationStatus = NSIntegerMin;

+ (void)initialize
{
    [super initialize];
    
    ALVungleInitialized = [[ALAtomicBoolean alloc] init];
}

#pragma mark - MAAdapter Methods

- (void)initializeWithParameters:(id<MAAdapterInitializationParameters>)parameters completionHandler:(void (^)(MAAdapterInitializationStatus, NSString * _Nullable))completionHandler
{
    [self updateUserPrivacySettingsForParameters: parameters consentDialogState: self.sdk.configuration.consentDialogState];
    if ( [ALVungleInitialized compareAndSet: NO update: YES] )
    {
        ALVungleIntializationStatus = MAAdapterInitializationStatusInitializing;
        
        NSString *appID = [parameters.serverParameters al_stringForKey: @"app_id"];
        [self log: @"Initializing Vungle SDK with app id: %@...", appID];
        
        [VungleAds setIntegrationName: @"max" version: ADAPTER_VERSION];
        [VungleAds initWithAppId: appID completion: ^(NSError * _Nullable error) {
            if ( error )
            {
                [self log: @"Vungle SDK failed to initialize with error: %@", error];
                
                ALVungleIntializationStatus = MAAdapterInitializationStatusInitializedFailure;
                NSString *errorString = [NSString stringWithFormat: @"%ld:%@", (long) error.code, error.localizedDescription];
                
                completionHandler(ALVungleIntializationStatus, errorString);
            }
            else
            {
                [self log: @"Vungle SDK initialized"];
                
                ALVungleIntializationStatus = MAAdapterInitializationStatusInitializedSuccess;
                
                completionHandler(ALVungleIntializationStatus, nil);
            }
        }];
    }
    else
    {
        completionHandler(ALVungleIntializationStatus, nil);
    }
}

- (NSString *)SDKVersion
{
    return [VungleAds sdkVersion];
}

- (NSString *)adapterVersion
{
    return ADAPTER_VERSION;
}

- (void)destroy
{
    self.interstitialRouter.interstitialAdDelegate = nil;
    self.vungleInterstitialAd = nil;
    self.interstitialRouter = nil;
    
    self.rewardedRouter.rewardedAdDelegate = nil;
    self.vungleRewardedVideoAd = nil;
    self.rewardedRouter = nil;
    
    [self.bannerRouter destroy];
    self.bannerRouter = nil;
    
    [self.nativeAdRouter destroy];
    self.nativeAdRouter = nil;
}

#pragma mark - GDPR

- (void)updateUserPrivacySettingsForParameters:(id<MAAdapterParameters>)parameters consentDialogState:(ALConsentDialogState)consentDialogState
{
    if ( consentDialogState == ALConsentDialogStateApplies )
    {
        NSNumber *hasUserConsent = [self privacySettingForSelector: @selector(hasUserConsent) fromParameters: parameters];
        if ( hasUserConsent )
        {
            [VunglePrivacySettings setGDPRStatus: hasUserConsent.boolValue];
            [VunglePrivacySettings setGDPRMessageVersion: @""];
        }
    }
    
    if ( ALSdk.versionCode >= 61100 )
    {
        NSNumber *isDoNotSell = [self privacySettingForSelector: @selector(isDoNotSell) fromParameters: parameters];
        if ( isDoNotSell )
        {
            [VunglePrivacySettings setCCPAStatus: isDoNotSell.boolValue];
        }
    }
    
    NSNumber *isAgeRestrictedUser = [self privacySettingForSelector: @selector(isAgeRestrictedUser) fromParameters: parameters];
    if ( isAgeRestrictedUser )
    {
        [VunglePrivacySettings setCOPPAStatus: isAgeRestrictedUser.boolValue];
    }
}

- (nullable NSNumber *)privacySettingForSelector:(SEL)selector fromParameters:(id<MAAdapterParameters>)parameters
{
    // Use reflection because compiled adapters have trouble fetching `BOOL` from old SDKs and `NSNumber` from new SDKs (above 6.14.0)
    NSMethodSignature *signature = [[parameters class] instanceMethodSignatureForSelector: selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature: signature];
    [invocation setSelector: selector];
    [invocation setTarget: parameters];
    [invocation invoke];
    
    // Privacy parameters return nullable `NSNumber` on newer SDKs
    if ( ALSdk.versionCode >= 6140000 )
    {
        NSNumber *__unsafe_unretained value;
        [invocation getReturnValue: &value];
        
        return value;
    }
    // Privacy parameters return BOOL on older SDKs
    else
    {
        BOOL rawValue;
        [invocation getReturnValue: &rawValue];
        
        return @(rawValue);
    }
}

#pragma mark - Signal Collection

- (void)collectSignalWithParameters:(id<MASignalCollectionParameters>)parameters andNotify:(id<MASignalCollectionDelegate>)delegate
{
    [self log: @"Collecting signal..."];
    
    NSString *signal = [VungleAds getBiddingToken];
    [delegate didCollectSignal: signal];
}

#pragma mark - MAInterstitialAdapter Methods

- (void)loadInterstitialAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAInterstitialAdapterDelegate>)delegate
{
    NSString *bidResponse = parameters.bidResponse;
    BOOL isBiddingAd = [bidResponse al_isValidString];
    NSString *placementIdentifier = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Loading %@interstitial ad for placement: %@...", ( isBiddingAd ? @"bidding " : @"" ), placementIdentifier];
    
    if ( ![VungleAds isInitialized] )
    {
        [self log: @"Vungle SDK not successfully initialized: failing interstitial ad load..."];
        [delegate didFailToLoadInterstitialAdWithError: MAAdapterError.notInitialized];
        
        return;
    }
    
    [self updateUserPrivacySettingsForParameters: parameters consentDialogState: self.sdk.configuration.consentDialogState];
    
    self.interstitialRouter = [[ALVungleMediationInterstitialAdapterRouter alloc] initVungleInterstitialAdDelegate: delegate parentAdapter: self];
    self.vungleInterstitialAd = [[VungleInterstitial alloc] initWithPlacementId: placementIdentifier];
    self.vungleInterstitialAd.delegate = self.interstitialRouter;
    
    if ( [self.vungleInterstitialAd canPlayAd] )
    {
        [self log: @"Interstitial ad loaded"];
        [delegate didLoadInterstitialAd];
        
        return;
    }
    [self.vungleInterstitialAd load: bidResponse];
}

- (void)showInterstitialAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAInterstitialAdapterDelegate>)delegate
{
    NSString *bidResponse = parameters.bidResponse;
    BOOL isBiddingAd = [bidResponse al_isValidString];
    NSString *placementIdentifier = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Showing %@interstitial ad for placement: %@...", ( isBiddingAd ? @"bidding " : @"" ), placementIdentifier];

    if ( self.vungleInterstitialAd && [self.vungleInterstitialAd canPlayAd] )
    {
        UIViewController *presentingViewController;
        if ( ALSdk.versionCode >= kALSdkVersionCode )
        {
            presentingViewController = parameters.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
        }
        else
        {
            presentingViewController = [ALUtils topViewControllerFromKeyWindow];
        }
        [self.vungleInterstitialAd presentWith: presentingViewController];
    }
}

#pragma mark - MARewardedAdapter Methods

- (void)loadRewardedAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MARewardedAdapterDelegate>)delegate
{
    NSString *bidResponse = parameters.bidResponse;
    BOOL isBiddingAd = [bidResponse al_isValidString];
    NSString *placementIdentifier = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Loading %@rewarded ad for placement: %@...", ( isBiddingAd ? @"bidding " : @"" ), placementIdentifier];
    
    if ( ![VungleAds isInitialized] )
    {
        [self log: @"Vungle SDK not successfully initialized: failing rewarded ad load..."];
        [delegate didFailToLoadRewardedAdWithError: MAAdapterError.notInitialized];
        
        return;
    }
    
    [self updateUserPrivacySettingsForParameters: parameters consentDialogState: self.sdk.configuration.consentDialogState];
    
    self.rewardedRouter = [[ALVungleMediationRewardedAdapterRouter alloc] initVungleRewardedAdDelegate: delegate parentAdapter: self];
    self.vungleRewardedVideoAd = [[VungleRewarded alloc] initWithPlacementId: placementIdentifier];
    self.vungleRewardedVideoAd.delegate = self.rewardedRouter;
    
    if ( [self.vungleRewardedVideoAd canPlayAd] )
    {
        [self log: @"Rewarded ad loaded"];
        [delegate didLoadRewardedAd];
        
        return;
    }
    [self.vungleRewardedVideoAd load: bidResponse];
}

- (void)showRewardedAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MARewardedAdapterDelegate>)delegate
{
    NSString *bidResponse = parameters.bidResponse;
    BOOL isBiddingAd = [bidResponse al_isValidString];
    NSString *placementIdentifier = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Showing %@rewarded ad for placement: %@...", ( isBiddingAd ? @"bidding " : @"" ), placementIdentifier];
    
    if ( self.vungleRewardedVideoAd && [self.vungleRewardedVideoAd canPlayAd] )
    {
        UIViewController *presentingViewController;
        if ( ALSdk.versionCode >= kALSdkVersionCode )
        {
            presentingViewController = parameters.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
        }
        else
        {
            presentingViewController = [ALUtils topViewControllerFromKeyWindow];
        }
        [self.vungleRewardedVideoAd presentWith: presentingViewController];
    }
}

#pragma mark - MAAdViewAdapter Methods

- (void)loadAdViewAdForParameters:(id<MAAdapterResponseParameters>)parameters adFormat:(MAAdFormat *)adFormat andNotify:(id<MAAdViewAdapterDelegate>)delegate
{
    NSString *bidResponse = parameters.bidResponse;
    BOOL isBiddingAd = [bidResponse al_isValidString];
    NSString *adFormatLabel = adFormat.label;
    NSString *placementIdentifier = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Loading %@%@ ad for placement: %@...", ( isBiddingAd ? @"bidding " : @"" ), adFormatLabel, placementIdentifier];
    
    if ( ![VungleAds isInitialized] )
    {
        [self log: @"Vungle SDK not successfully initialized: failing %@ ad load...", adFormatLabel];
        [delegate didFailToLoadAdViewAdWithError: MAAdapterError.notInitialized];
        
        return;
    }
    
    [self updateUserPrivacySettingsForParameters: parameters consentDialogState: self.sdk.configuration.consentDialogState];
    
    self.bannerRouter = [[ALVungleMediationAdViewAdapterRouter alloc] initVungleAdViewAdDelegate: delegate parentAdapter: self parameters: parameters adFormat: adFormat];
    [self.bannerRouter loadAdView: placementIdentifier];
}

#pragma mark - MANativeAdAdapter Methods

- (void)loadNativeAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MANativeAdAdapterDelegate>)delegate
{
    NSString *placementIdentifier = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Loading Native ad for placement: %@...", placementIdentifier];
    
    if ( ![VungleAds isInitialized] )
    {
        [self log: @"Vungle SDK not successfully initialized: failing Native ad load..."];
        [delegate didFailToLoadNativeAdWithError: MAAdapterError.notInitialized];
        return;
    }
    [self updateUserPrivacySettingsForParameters: parameters consentDialogState: self.sdk.configuration.consentDialogState];
    self.nativeAdRouter = [[ALVungleMediationNativeAdAdapter alloc] initVungleNativeAdDelegate: delegate parameters: parameters];
    [self.nativeAdRouter requestNativeAd: placementIdentifier];
}

#pragma mark - Shared Methods

+ (MAAdapterError *)toMaxError:(nullable NSError *)vungleError
{
    if ( !vungleError ) return MAAdapterError.unspecified;
    
    int vungleErrorCode = (int)vungleError.code;
    MAAdapterError *adapterError = MAAdapterError.unspecified;
    switch (vungleErrorCode) {
        case 6: //sdkNotInitialized
            adapterError = MAAdapterError.notInitialized;
            break;
        case 2: //invalidAppID
        case 201: //invalidPlacementID
        case 500: //bannerViewInvalidSize
            adapterError = MAAdapterError.invalidConfiguration;
            break;
        case 210: //adNotLoaded
            adapterError = MAAdapterError.noFill;
            break;
        case 212: //placementSleep
        case 304: //adExpired
            adapterError = MAAdapterError.invalidLoadState;
            break;
        case 303: //adIsntReady
            adapterError = MAAdapterError.adNotReady;
            break;
        case 600: //nativeAssetError
            adapterError = MAAdapterError.missingRequiredNativeAdAssets;
            break;
        default:
            adapterError = MAAdapterError.internalError;
            break;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [MAAdapterError errorWithCode: adapterError.errorCode
                             errorString: adapterError.errorMessage
                  thirdPartySdkErrorCode: vungleErrorCode
               thirdPartySdkErrorMessage: vungleError.localizedDescription];
#pragma clang diagnostic pop
}

@end

@implementation ALVungleMediationInterstitialAdapterRouter

- (instancetype)initVungleInterstitialAdDelegate:(id<MAInterstitialAdapterDelegate>)interstitialAdDelegate parentAdapter:(ALVungleMediationAdapter *)parentAdapter
{
    self = [super init];
    if ( self )
    {
        self.interstitialAdDelegate = interstitialAdDelegate;
        self.parentAdapter = parentAdapter;
    }
    return self;
}

#pragma mark - VungleInterstitialDelegate

- (void)interstitialAdDidLoad:(VungleInterstitial * _Nonnull)interstitial
{
    [self.interstitialAdDelegate didLoadInterstitialAd];
}

- (void)interstitialAdDidFailToLoad:(VungleInterstitial * _Nonnull)interstitial withError:(NSError * _Nonnull)withError
{
    MAAdapterError *adapterError = [ALVungleMediationAdapter toMaxError: withError];
    [self.parentAdapter log: @"Interstitial failed to load with error: %@", adapterError];
    [self.interstitialAdDelegate didFailToLoadInterstitialAdWithError: adapterError];
}

- (void)interstitialAdDidPresent:(VungleInterstitial * _Nonnull)interstitial
{
    NSString *creativeIdentifier = interstitial.creativeId;
    if ( ALSdk.versionCode >= kALSdkVersionNeeded && [creativeIdentifier al_isValidString] )
    {
        [self.interstitialAdDelegate didDisplayInterstitialAdWithExtraInfo: @{@"creative_id" : creativeIdentifier}];
    }
    else
    {
        [self.interstitialAdDelegate didDisplayInterstitialAd];
    }
}

- (void)interstitialAdDidFailToPresent:(VungleInterstitial * _Nonnull)interstitial withError:(NSError * _Nonnull)withError
{
    MAAdapterError *adapterError = [MAAdapterError errorWithCode: kALErrorCode errorString: @"Ad Display Failed" mediatedNetworkErrorCode: withError.code mediatedNetworkErrorMessage: withError.localizedDescription];;
    [self.parentAdapter log: @"Interstitial ad failed to display with error: %@", adapterError];
    [self.interstitialAdDelegate didFailToDisplayInterstitialAdWithError: adapterError];
}

- (void)interstitialAdDidClose:(VungleInterstitial * _Nonnull)interstitial
{
    [self.interstitialAdDelegate didHideInterstitialAd];
}

- (void)interstitialAdDidClick:(VungleInterstitial * _Nonnull)interstitial
{
    [self.interstitialAdDelegate didClickInterstitialAd];
}

@end

@implementation ALVungleMediationRewardedAdapterRouter

- (instancetype)initVungleRewardedAdDelegate:(id<MARewardedAdapterDelegate>)rewardedAdDelegate parentAdapter:(ALVungleMediationAdapter *)parentAdapter
{
    self = [super init];
    if ( self )
    {
        self.rewardedAdDelegate = rewardedAdDelegate;
        self.parentAdapter = parentAdapter;
    }
    return self;
}

#pragma mark - VungleRewardedDelegate

- (void)rewardedAdDidLoad:(VungleRewarded * _Nonnull)rewarded
{
    [self.rewardedAdDelegate didLoadRewardedAd];
}

- (void)rewardedAdDidFailToLoad:(VungleRewarded * _Nonnull)rewarded withError:(NSError * _Nonnull)withError
{
    MAAdapterError *adapterError = [ALVungleMediationAdapter toMaxError: withError];
    [self.parentAdapter log: @"Rewarded failed to load with error: %@", adapterError];
    [self.rewardedAdDelegate didFailToLoadRewardedAdWithError: adapterError];
}

- (void)rewardedAdDidPresent:(VungleRewarded * _Nonnull)rewarded
{
    NSString *creativeIdentifier = rewarded.creativeId;
    if ( ALSdk.versionCode >= kALSdkVersionNeeded && [creativeIdentifier al_isValidString] )
    {
        [self.rewardedAdDelegate didDisplayRewardedAdWithExtraInfo: @{@"creative_id" : creativeIdentifier}];
    }
    else
    {
        [self.rewardedAdDelegate didDisplayRewardedAd];
    }
    [self.rewardedAdDelegate didStartRewardedAdVideo];
}

- (void)rewardedAdDidFailToPresent:(VungleRewarded * _Nonnull)rewarded withError:(NSError * _Nonnull)withError
{
    MAAdapterError *adapterError = [MAAdapterError errorWithCode: kALErrorCode errorString: @"Ad Display Failed" mediatedNetworkErrorCode: withError.code mediatedNetworkErrorMessage: withError.localizedDescription];
    [self.parentAdapter log: @"Rewarded ad failed to display with error: %@", adapterError];
    [self.rewardedAdDelegate didFailToDisplayRewardedAdWithError:adapterError];
}

- (void)rewardedAdDidClose:(VungleRewarded * _Nonnull)rewarded
{
    [self.rewardedAdDelegate didHideRewardedAd];
}

- (void)rewardedAdDidClick:(VungleRewarded * _Nonnull)rewarded
{
    [self.rewardedAdDelegate didClickRewardedAd];
}

- (void)rewardedAdDidRewardUser:(VungleRewarded * _Nonnull)rewarded
{
    MAReward *reward = [self.parentAdapter reward];
    [self.parentAdapter log: @"Rewarded user with reward: %@", reward];
    [self.rewardedAdDelegate didRewardUserWithReward: reward];
}

@end

@implementation ALVungleMediationAdViewAdapterRouter

- (instancetype)initVungleAdViewAdDelegate:(id<MAAdViewAdapterDelegate>)adViewAdDelegate parentAdapter:(ALVungleMediationAdapter *)parentAdapter parameters:(id<MAAdapterResponseParameters>)parameters adFormat:(MAAdFormat *)adFormat
{
    self = [super init];
    if ( self )
    {
        self.adViewAdDelegate = adViewAdDelegate;
        self.parameters = parameters;
        self.adFormat = adFormat;
        self.parentAdapter = parentAdapter;
    }
    return self;
}

- (void)loadAdView:(NSString *)placementIdentifier {
    BannerSize size = [self vungleBannerAdSizeFromFormat: self.adFormat];
    self.vungleBannerAd = [[VungleBanner alloc] initWithPlacementId: placementIdentifier size: size];
    self.vungleBannerAd.delegate = self;
    self.vungleBannerAd.enableRefresh = NO;
    
    if ( MAAdFormat.banner == self.adFormat )
    {
        self.adView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, 50)];
    }
    else if ( MAAdFormat.leader == self.adFormat )
    {
        self.adView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 728, 90)];
    }
    else if ( MAAdFormat.mrec == self.adFormat )
    {
        self.adView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 300, 250)];
    }
    else
    {
        [NSException raise: NSInvalidArgumentException format: @"Invalid ad format: %@", self.adFormat.label];
    }
    
    if ( [self.vungleBannerAd canPlayAd] )
    {
        [self showAdViewAdForParameters: self.parameters adFormat: self.adFormat];
        
        return;
    }
    
    NSString *bidResponse = self.parameters.bidResponse;
    [self.vungleBannerAd load: bidResponse];
}

- (void)showAdViewAdForParameters:(id<MAAdapterResponseParameters>)parameters adFormat:(MAAdFormat *)adFormat
{
    NSString *bidResponse = parameters.bidResponse;
    BOOL isBiddingAd = [bidResponse al_isValidString];
    NSString *adFormatLabel = adFormat.label;
    NSString *placementIdentifier = parameters.thirdPartyAdPlacementIdentifier;
    [self.parentAdapter log: @"Showing %@%@ ad for placement: %@...", ( isBiddingAd ? @"bidding " : @"" ), adFormatLabel, placementIdentifier];
    
    if ( [self.vungleBannerAd canPlayAd] )
    {
        [self.vungleBannerAd presentOn: self.adView];
    }
}

- (BannerSize)vungleBannerAdSizeFromFormat:(MAAdFormat *)adFormat
{
    if ( adFormat == MAAdFormat.banner )
    {
        return BannerSizeRegular;
    }
    else if ( adFormat == MAAdFormat.leader )
    {
        return BannerSizeLeaderboard;
    }
    else if ( adFormat == MAAdFormat.mrec )
    {
        return BannerSizeMrec;
    }
    return BannerSizeRegular;
}

- (void)destroy {
    self.adView = nil;
    self.adViewAdDelegate = nil;
    self.vungleBannerAd = nil;
}

#pragma mark - VungleBannerDelegate

- (void)bannerAdDidLoad:(VungleBanner * _Nonnull)banner
{
    [self.adViewAdDelegate didLoadAdForAdView: self.adView];
    [self showAdViewAdForParameters: self.parameters adFormat: self.adFormat];
}

- (void)bannerAdDidFailToLoad:(VungleBanner * _Nonnull)banner withError:(NSError * _Nonnull)withError
{
    MAAdapterError *adapterError = [ALVungleMediationAdapter toMaxError: withError];
    [self.parentAdapter log: @"Banner ad failed to load with error: %@", adapterError];
    [self.adViewAdDelegate didFailToLoadAdViewAdWithError: adapterError];
}

- (void)bannerAdDidPresent:(VungleBanner * _Nonnull)banner
{
    NSString *creativeIdentifier = banner.creativeId;
    if ( ALSdk.versionCode >= kALSdkVersionNeeded && [creativeIdentifier al_isValidString] )
    {
        [self.adViewAdDelegate didDisplayAdViewAdWithExtraInfo: @{@"creative_id" : creativeIdentifier}];
    }
    else
    {
        [self.adViewAdDelegate didDisplayAdViewAd];
    }
}

- (void)bannerAdDidFailToPresent:(VungleBanner * _Nonnull)banner withError:(NSError * _Nonnull)withError
{
    MAAdapterError *adapterError = [MAAdapterError errorWithCode: kALErrorCode errorString: @"Ad Display Failed" mediatedNetworkErrorCode: withError.code mediatedNetworkErrorMessage: withError.localizedDescription];
    [self.parentAdapter log: @"Banner ad failed to display with error: %@", adapterError];
    [self.adViewAdDelegate didFailToDisplayAdViewAdWithError: adapterError];
}

- (void)bannerAdDidClose:(VungleBanner * _Nonnull)banner
{
    [self.adViewAdDelegate didHideAdViewAd];
}

- (void)bannerAdDidClick:(VungleBanner * _Nonnull)banner
{
    [self.adViewAdDelegate didClickAdViewAd];
}

@end

@implementation ALVungleMediationNativeAdAdapter

- (instancetype)initVungleNativeAdDelegate:(id<MANativeAdAdapterDelegate>)nativeAdDelegate parameters:(id<MAAdapterResponseParameters>)parameters
{
    self = [super init];
    if ( self )
    {
        self.nativeAdDelegate = nativeAdDelegate;
        self.parameters = parameters;
    }
    return self;
}

- (void)requestNativeAd:(NSString *)placementIdentifier
{
    if ( ![VungleAds isInitialized] )
    {
      return;
    }
    [self loadVungleNativeAd: placementIdentifier];
}

- (void)playNativeAd
{
    if ( !self.vungleNativeAd )
    {
        [self.nativeAdDelegate didFailToLoadNativeAdWithError: MAAdapterError.noFill];
        return;
    }
    dispatchOnMainQueue(^{
        MANativeAd *maNativeAd = [[MAVungleNativeAd alloc] initWithParentAdapter: self builderBlock: ^(MANativeAdBuilder * _Nonnull builder) {
            MediaView *mediaView = [[MediaView alloc] init];
            builder.mediaView = mediaView;
            builder.title = self.vungleNativeAd.title;
            builder.body = self.vungleNativeAd.bodyText;
            builder.callToAction = self.vungleNativeAd.callToAction;
            builder.icon = [[MANativeAdImage alloc] initWithImage: self.vungleNativeAd.iconImage];
        }];
        [self.nativeAdDelegate didLoadAdForNativeAd: maNativeAd withExtraInfo: nil];
    });
}

- (void)unregisterNativeAd
{
    if ( self.vungleNativeAd )
    {
        [self.vungleNativeAd unregisterView];
    }
}

- (void)loadVungleNativeAd:(NSString *)placementIdentifier
{
    self.vungleNativeAd = [[VungleNative alloc] initWithPlacementId: placementIdentifier];
    self.vungleNativeAd.delegate = self;
    self.vungleNativeAd.adOptionsPosition = NativeAdOptionsPositionTopRight;
    [self.vungleNativeAd load: self.parameters.bidResponse];
}

- (void)nativeAdDidLoad:(VungleNative * _Nonnull)native
{
    [self playNativeAd];
}

- (void)nativeAdDidFailToLoad:(VungleNative * _Nonnull)native withError:(NSError * _Nonnull)withError
{
    MAAdapterError *adapterError = [ALVungleMediationAdapter toMaxError: withError];
    [self.nativeAdDelegate didFailToLoadNativeAdWithError: adapterError];
}

- (void)nativeAdDidTrackImpression:(VungleNative * _Nonnull)native
{
    NSString *creativeIdentifier = native.creativeId;
    if ( ALSdk.versionCode >= kALSdkVersionNeeded && [creativeIdentifier al_isValidString] )
    {
        [self.nativeAdDelegate didDisplayNativeAdWithExtraInfo: @{@"creative_id" : creativeIdentifier}];
    }
    else
    {
        [self.nativeAdDelegate didDisplayNativeAdWithExtraInfo: nil];
    }
}

- (void)nativeAdDidClick:(VungleNative * _Nonnull)native
{
    [self.nativeAdDelegate didClickNativeAd];
}

- (void)destroy {
    self.nativeAdDelegate = nil;
    [self unregisterNativeAd];
    self.vungleNativeAd = nil;
}

@end

@implementation MAVungleNativeAd

- (instancetype)initWithParentAdapter:(ALVungleMediationNativeAdAdapter *)parentAdapter builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock
{
    self = [super initWithFormat: MAAdFormat.native builderBlock: builderBlock];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
    }
    return self;
}

- (void)prepareViewForInteraction:(MANativeAdView *)nativeAdView
{
    if ( !self.parentAdapter.vungleNativeAd )
    {
        return;
    }
    
    NSMutableArray *clickableViews = [NSMutableArray array];
    if ( [self.title al_isValidString] && nativeAdView.titleLabel )
    {
        [clickableViews addObject: nativeAdView.titleLabel];
    }
    if ( [self.body al_isValidString] && nativeAdView.bodyLabel )
    {
        [clickableViews addObject: nativeAdView.bodyLabel];
    }
    if ( [self.callToAction al_isValidString] && nativeAdView.callToActionButton )
    {
        [clickableViews addObject: nativeAdView.callToActionButton];
    }
    if ( self.icon && nativeAdView.iconImageView )
    {
        [clickableViews addObject: nativeAdView.iconImageView];
    }
    if ( self.mediaView && nativeAdView.mediaContentView )
    {
        [clickableViews addObject: nativeAdView.mediaContentView];
    }
    
    [self.parentAdapter.vungleNativeAd registerViewForInteractionWithView: nativeAdView
                                                                mediaView: (MediaView *) self.mediaView
                                                            iconImageView: nativeAdView.iconImageView
                                                           viewController: [ALUtils topViewControllerFromKeyWindow]
                                                           clickableViews: clickableViews];
}

@end
