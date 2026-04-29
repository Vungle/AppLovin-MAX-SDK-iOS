# ADR-003: Programmatic Bidding Signal Support

## Status
Accepted

## Context
Programmatic bidding (in-app bidding) requires adapters to collect bid signals from the network SDK before the auction. This is fundamentally different from the waterfall model where ads are requested sequentially. Bidding-capable adapters must provide signals synchronously or asynchronously before ad requests.

## Decision
Bidding-capable adapters implement signal collection methods as part of the MAAdapter protocol. The adapter:
1. Collects a bid token/signal from the network SDK
2. Returns it to MAX for inclusion in the unified auction
3. Receives the auction result and loads the winning ad with the bid response

The same adapter class handles both bidding and waterfall flows, with the MAX SDK determining which path to use based on mediation configuration.

## Consequences
- Adapters that support bidding participate in real-time unified auctions
- Signal collection must be fast to avoid auction timeouts
- Same adapter class handles both bidding and waterfall, reducing code duplication
- Network SDKs must expose bid signal APIs for this to work
- Increased revenue potential through competitive real-time bidding
- Adapter complexity increases with dual-path (bidding + waterfall) support
