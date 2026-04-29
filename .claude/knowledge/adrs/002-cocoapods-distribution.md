# ADR-002: CocoaPods-Based Distribution

## Status
Accepted

## Context
Each network adapter depends on the AppLovin SDK and a third-party network SDK. Adapters need independent versioning since network SDKs update on different schedules. Publishers integrate only the adapters they need.

## Decision
Each adapter is distributed as an independent CocoaPod with its own podspec (`AppLovinMediation{Network}Adapter.podspec`). The podspec declares:
- Dependency on `AppLovinSDK` (>= minimum version)
- Dependency on the third-party network SDK (pinned version)
- Minimum iOS deployment target
- Source files within the adapter directory

No Swift Package Manager support is provided.

## Consequences
- Publishers can integrate any subset of adapters independently
- Each adapter can version and release on its own schedule
- Podspec version encodes the underlying SDK version (e.g., `6.9.1.0` = SDK 6.9.1, patch 0)
- CocoaPods resolves transitive dependency conflicts automatically
- Lack of SPM support limits adoption for SPM-only projects
- Each adapter directory is self-contained with podspec + source + changelog
