# ADR 0002: SwiftUI + SwiftData on iOS 17+

## Status

Accepted

## Context

MVP needs a native iOS UI, local persistence for one Companion and its Vital Stats, and fast iteration. Alternatives: UIKit + Core Data, or UIKit + SwiftUI hybrid.

## Decision

Build with **SwiftUI** for all screens. Persist data with **SwiftData**. Target **iOS 17+** minimum.

## Consequences

**Positive:**
- SwiftData integrates cleanly with SwiftUI (`@Model`, `@Query`)
- Modern Swift concurrency (`async/await`) for Generation API calls
- No legacy iOS compatibility burden for a greenfield hobby/MVP project

**Negative:**
- Excludes devices stuck on iOS 16 (acceptable for MVP)
- SwiftData is newer than Core Data — fewer Stack Overflow answers, but sufficient for one-entity persistence
