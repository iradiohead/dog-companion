# ADR 0003: MVVM Architecture

## Status

Accepted

## Context

MVP has 5 screens, one API service, passive stat decay logic, and SwiftData persistence. Need a structure that stays maintainable without over-engineering.

## Decision

Use **MVVM**:

- **Views** — SwiftUI, one per screen
- **ViewModels** — `@Observable` classes for screen logic and Vital Stat decay
- **Services** — `GenerationService` for Replicate API calls
- **Models** — SwiftData `@Model` for `Companion` entity

## Consequences

**Positive:**
- Clear separation: UI vs business logic vs network
- ViewModels are testable without SwiftUI
- Familiar pattern, low onboarding cost

**Negative:**
- More files than "everything in View" — acceptable at 5 screens
