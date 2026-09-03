# ADR 0001: Cloud-Based Comic Portrait Generation

## Status

Accepted

## Context

Comic Portrait generation is the app's core differentiator. The Owner provides a Source Photo and expects a Comic Portrait that preserves fur color and breed characteristics. Options considered:

- **Cloud API** (Replicate or similar img2img / IP-Adapter models)
- **On-device Core ML** (smaller models, limited quality)
- **Preset breed templates + color mapping** (stable but weak similarity)

MVP has no user accounts, no subscription, and targets a demoable product in 2–4 weeks.

## Decision

Use a **cloud image-generation API** (Replicate) for Comic Portrait creation. Cache the resulting image locally. Do not persist the Source Photo after generation completes.

## Consequences

**Positive:**
- Best similarity quality within MVP timeline
- Fast iteration on Style Templates by swapping models/prompts
- Small on-device binary (no large ML model bundled)

**Negative:**
- Requires network at Companion creation time
- Per-generation API cost (acceptable for MVP / developer-funded)
- Privacy: Source Photo is sent to a third party — must disclose in App Store privacy policy before commercial release
- API key must not ship in the client binary for production; a thin backend proxy is required before App Store launch

## Alternatives Considered

- **On-device Core ML**: Better privacy, but quality insufficient for "recognizably my dog" at MVP scope.
- **Template mapping**: Predictable and free, but fails the core value proposition.
