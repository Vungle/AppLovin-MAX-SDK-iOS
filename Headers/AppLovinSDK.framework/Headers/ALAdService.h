//
//  ALAdService.h
//  AppLovinSDK
//
//  Created by Basil on 2/27/12.
//  Copyright © 2020 AppLovin Corporation. All rights reserved.
//

#import "ALAd.h"
#import "ALAdSize.h"
#import "ALAdLoadDelegate.h"
#import "ALAdDisplayDelegate.h"
#import "ALAdVideoPlaybackDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * This class provides and displays ads.
 */
@interface ALAdService : NSObject

/**
 * Fetches a new ad, of a given size, and notifies a supplied delegate on completion.
 *
 * @param adSize    Size of an ad to load. Must not be `nil`.
 * @param delegate  A callback that `loadNextAd` calls to notify of the fact that the ad is loaded.
 */
- (void)loadNextAd:(ALAdSize *)adSize andNotify:(id<ALAdLoadDelegate>)delegate;

/**
 * Fetches a new ad, for a given zone, and notifies a supplied delegate on completion.
 *
 * @param zoneIdentifier  The identifier of the zone to load an ad for. Must not be `nil`.
 * @param delegate        A callback that `loadNextAdForZoneIdentifier` calls to notify of the fact that the ad is loaded.
 */
- (void)loadNextAdForZoneIdentifier:(NSString *)zoneIdentifier andNotify:(id<ALAdLoadDelegate>)delegate;

/**
 * Generates a token used for advanced header bidding.
 */
@property (nonatomic, copy, readonly) NSString *bidToken;

/**
 * Fetches a new ad for the given ad token. The provided ad token must be one that was received from AppLovin S2S API.
 *
 * <b>Note:</b> this method is designed to be called by SDK mediation providers. Use `loadNextAdForZoneIdentifier:andNotify:` for regular integrations.
 *
 * @param adToken   Ad token returned from AppLovin S2S API. Must not be `nil`.
 * @param delegate  A callback that `loadNextAdForAdToken` calls to notify that the ad has been loaded. Must not be `nil`.
 */
- (void)loadNextAdForAdToken:(NSString *)adToken andNotify:(id<ALAdLoadDelegate>)delegate;

/**
 * Fetch a new ad for any of the provided zone identifiers.
 *
 * <b>Please note:</b> this method is designed to be called by SDK mediation providers. Please use `loadNextAdForZoneIdentifier:andNotify:` for regular
 * integrations.
 *
 * @param zoneIdentifiers  An array of zone identifiers for which an ad should be loaded. Must not be `nil`.
 * @param delegate         A callback that `loadNextAdForZoneIdentifiers` calls to notify that the ad has been loaded. Must not be `nil`.
 */
- (void)loadNextAdForZoneIdentifiers:(NSArray<NSString *> *)zoneIdentifiers andNotify:(id<ALAdLoadDelegate>)delegate;

/**
 * Access ALAdService through {@link ALSdk}'s `adService` property instead.
 */
- (instancetype)init __attribute__((unavailable("Access ALAdService through ALSdk's adService property.")));
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface ALAdService(ALDeprecated)
/**
 * @deprecated Manually preloading ads in the background has been deprecated and will be removed in a future SDK version. Please use `[ALAdService loadNextAd:andNotify:]` to load ads to display.
 */
- (void)preloadAdOfSize:(ALAdSize *)adSize __deprecated_msg("Manually preloading ads in the background has been deprecated and will be removed in a future SDK version. Please use [ALAdService loadNextAd:andNotify:] to load ads to display.");
/**
 * @deprecated Manually preloading ads in the background has been deprecated and will be removed in a future SDK version. Please use `[ALAdService loadNextAdForZoneIdentifier:andNotify:]` to load ads to display.
 */
- (void)preloadAdForZoneIdentifier:(NSString *)zoneIdentifier __deprecated_msg("Manually preloading ads in the background has been deprecated and will be removed in a future SDK version. Please use [ALAdService loadNextAdForZoneIdentifier:andNotify:] to load ads to display.");
/**
 * @deprecated Manually preloading ads in the background has been deprecated and will be removed in a future SDK version. Please use `[ALAdService loadNextAd:andNotify:]` to load ads to display.
 */
- (BOOL)hasPreloadedAdOfSize:(ALAdSize *)adSize __deprecated_msg("Manually preloading ads in the background has been deprecated and will be removed in a future SDK version. Please use [ALAdService loadNextAd:andNotify:] to load ads to display.");
/**
 * @deprecated Manually preloading ads in the background has been deprecated and will be removed in a future SDK version. Please use `[ALAdService loadNextAdForZoneIdentifier:andNotify:]` to load ads to display.
 */
- (BOOL)hasPreloadedAdForZoneIdentifier:(NSString *)zoneIdentifier __deprecated_msg("Manually preloading ads in the background has been deprecated and will be removed in a future SDK version. Please use [ALAdService loadNextAdForZoneIdentifier:andNotify:] to load ads to display.");
@end

NS_ASSUME_NONNULL_END