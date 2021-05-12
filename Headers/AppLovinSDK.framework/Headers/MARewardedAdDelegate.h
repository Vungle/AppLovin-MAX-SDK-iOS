//
//  MARewardedAdDelegate.h
//  AppLovinSDK
//
//  Created by Thomas So on 8/10/18.
//  Copyright © 2020 AppLovin Corporation. All rights reserved.
//

#import "MAAdDelegate.h"
#import "MAReward.h"
#import "MAAd.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * This delegate is notified when a user watches a rewarded video and of whether a reward was granted or rejected.
 */
@protocol MARewardedAdDelegate<MAAdDelegate>

/**
 * This method is invoked when rewarded video has started.
 */
- (void)didStartRewardedVideoForAd:(MAAd *)ad;

/**
 * This method is invoked when rewarded video has completed.
 */
- (void)didCompleteRewardedVideoForAd:(MAAd *)ad;

/**
 * This method is invoked when a user should be granted a reward.
 *
 * @param ad     Ad for which the reward ad was rewarded.
 * @param reward The reward to be granted to the user.
 */
- (void)didRewardUserForAd:(MAAd *)ad withReward:(MAReward *)reward;

@end

NS_ASSUME_NONNULL_END
