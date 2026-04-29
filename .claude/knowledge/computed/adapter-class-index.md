# AppLovin MAX — Vungle/Liftoff iOS Adapter Class Index

## Adapter Entry Point

| Class | Superclass | File |
|-------|-----------|------|
| `ALVungleMediationAdapter` | `ALMediationAdapter` | `AppLovin-MAX-SDK-iOS/ALVungleMediationAdapter.m` |

**SDK Version**: Reported via `+sdkVersion` and `+adapterVersion`
**Initialization**: `initializeWithParameters:completionHandler:` — calls `[VungleAds initWithAppId:]`

## Format Delegates

| Format | Delegate Class | Protocol | Callback Flow |
|--------|---------------|----------|---------------|
| Interstitial | `ALVungleMediationAdapterInterstitialAdDelegate` | `ALMediationInterstitialAdapter` | `interstitialAdDidLoad:` → `didLoadAd`, `interstitialAdDidFailToLoad:withError:` → `didFailToLoadWithError:` |
| Rewarded | `ALVungleMediationAdapterRewardedAdDelegate` | `ALMediationRewardedAdapter` | `rewardedAdDidLoad:` → `didLoadAd`, `rewardedAdDidRewardUser:` → `didRewardUser` |
| Banner | `ALVungleMediationAdapterBannerAdDelegate` | `ALMediationBannerAdapter` | `bannerAdDidLoad:` → `didLoadAd`, size mapping via `bannerFormatForAdSize:` |
| Native | `ALVungleMediationAdapterNativeAdDelegate` | `ALMediationNativeAdapter` | `nativeAdDidLoad:` → `didLoadAd`, extracts title/body/icon/media/CTA |

## Callback Mapping (Vungle → AppLovin MAX)

| Vungle Callback | MAX Callback | Context |
|----------------|-------------|---------|
| `adDidLoad:` | `didLoadAd` | All formats |
| `adDidFailToLoad:withError:` | `didFailToLoadWithError:` | All formats |
| `adWillPresent:` | `didDisplayAd` | Fullscreen (interstitial, rewarded) |
| `adDidClick:` | `didClickAd` | All formats |
| `adDidClose:` | `didHideAd` | Fullscreen |
| `adDidRewardUser:` | `didRewardUser` | Rewarded only |
| `adDidTrackImpression:` | `didPayRevenue` | Revenue tracking |

## Bidding Support

- Implements `ALMediationAdapterBidding` protocol
- `collectSignalWithParameters:completionHandler:` → calls `[VungleAds getBiddingToken]`
- Bid response token passed via `localExtraParameters[@"bid_payload"]`

## Key Patterns

1. **Delegate-per-format**: Each ad format has its own delegate class, all inner classes of the main adapter
2. **Singleton initialization**: `VungleAds` initialized once, shared across all format delegates
3. **Size mapping**: Banner sizes mapped via helper `bannerFormatForAdSize:` (320×50, 728×90, 300×250, MREC)
4. **Privacy**: GDPR consent, CCPA opt-out, COPPA age-restricted flags forwarded to Vungle SDK
