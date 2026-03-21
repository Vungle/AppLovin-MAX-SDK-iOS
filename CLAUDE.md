# AppLovin MAX SDK iOS

## Overview
AppLovin MAX iOS mediation SDK with 25+ network adapters. Each adapter wraps a third-party ad network SDK to serve ads through the AppLovin MAX platform.

## Languages
- **Objective-C**: All adapter implementations
- **Swift**: Demo/example apps

## Build System
- **CocoaPods**: Each adapter has its own `AppLovinMediation{Network}Adapter.podspec`
- **Xcode projects**: For demo apps and testing
- **No SPM support**

## Architecture
- Each adapter implements the `MAAdapter` protocol with format-specific sub-protocols:
  - `MAInterstitialAdapter` — fullscreen interstitial ads
  - `MARewardedAdapter` — rewarded video ads
  - `MAAdViewAdapter` — banner and MREC ads
  - `MANativeAdAdapter` — native ad formats
  - App Open ads where supported
- Directory structure: `{Network}Adapter/` containing `AL{Network}MediationAdapter.h/.m` + podspec + `CHANGELOG.md`

## Vungle Adapter
- Main class: `ALVungleMediationAdapter`
- Supports bidding signal collection for programmatic demand
- Ad formats: Interstitial, Rewarded, Banner/MREC, Native

## Platform Requirements
- Min iOS: 11.0–12.0 (varies by adapter)
- AppLovinSDK >= 13.0.0

## Demo Apps
- Swift demo app and ObjC demo app in separate directories
- Used for manual integration testing

## Key Conventions
- One adapter directory per network
- Podspec per adapter for independent versioning
- CHANGELOG.md per adapter tracking version history
- Adapter naming: `AL{Network}MediationAdapter`
