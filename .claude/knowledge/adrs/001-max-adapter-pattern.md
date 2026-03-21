# ADR-001: Standardized MAX Adapter Interface

## Status
Accepted

## Context
AppLovin MAX mediates ads from 25+ network SDKs on iOS. Each network has different APIs, threading models, and lifecycle patterns. A consistent adapter interface is needed to normalize these differences.

## Decision
All network adapters implement the `MAAdapter` protocol with format-specific sub-protocols:
- `MAInterstitialAdapter` for fullscreen interstitial ads
- `MARewardedAdapter` for rewarded video ads
- `MAAdViewAdapter` for banner and MREC ads
- `MANativeAdAdapter` for native ad formats

Each adapter is a single class (`AL{Network}MediationAdapter`) that implements all supported format protocols. The adapter manages SDK initialization, ad loading, ad display, and callback forwarding.

## Consequences
- Uniform interface allows MAX SDK to treat all networks identically
- Single adapter class per network keeps the mapping simple
- Adapters must handle threading internally (callbacks to MAX must be on main thread)
- Adding a new ad format requires a new protocol but existing adapters can adopt incrementally
- Adapter authors must understand both the MAX protocol and the network SDK
