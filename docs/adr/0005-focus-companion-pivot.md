# ADR 0005: Pivot to Focus Companion (Cat On Chair for Dogs)

## Status

Accepted

The app pivots from a virtual-pet care loop (Feed / Play / Walk, Hunger / Mood) to a focus-companion experience modeled on Cat On Chair: the Owner's own dog — generated from a Source Photo — keeps them company during Focus Sessions in a decorated Scene.

## Decision

**Product:** Pomodoro focus timer + personalized animated dog companion. Remove Vital Stats and Care Actions entirely.

**Visual pipeline:** Source Photo → identity-preserving Comic Portrait (DashScope) → on-device Matting Cutout → SpriteKit part motion on that Cutout. Shared paper puppet is fallback only. No AI video, no extra pose images. See [ADR 0006](0006-shared-paper-puppet.md).

**Scenes:** AI-generated background and furniture illustrations, bundled as static assets at build time — not generated per user at runtime.

**Rewards:** Completing a Focus Session yields a Gift that directly unlocks Furniture or Decor. No fish/currency layer in v1.

**Widget:** Static home-screen widget (focus status + Scene snapshot) in v1; multi-frame animated widget deferred to v1.1.

**Regeneration:** Retained, limited to 3 per Companion, re-runs Comic Portrait generation and Cutout matting.

## Considered Options

- **Keep virtual-pet loop alongside focus timer:** Rejected — two competing core loops would dilute the product.
- **AI image-to-video for Motion:** Rejected for v1 — high cost, slow, inconsistent loop quality; procedural Cutout animation ships faster and more reliably.
- **On-device Vision matting:** Rejected — poor results on stylized Comic Portraits; cloud matting aligns with existing DashScope stack.
- **Fish economy (Cat On Chair model):** Deferred — direct unlock from Gifts is sufficient for v1.

## Consequences

- Large removal of existing code: `VitalStatsCalculator`, Care Action UI, `ExpressionTier`, hunger/mood model fields.
- `Companion` model gains `cutoutData`; loses `hunger`, `mood`.
- New domains: `FocusSession`, `Scene`, `Gift`, `MattingService`, `MotionView`, Widget extension.
- Cat On Chair uses hand-drawn preset sprites; our per-user Cutout + procedural Motion will look less polished — accepted trade-off for personalization.
