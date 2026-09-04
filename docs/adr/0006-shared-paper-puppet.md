# ADR 0006: Shared paper puppet instead of per-user cutout motion

## Status

Accepted

Supersedes the visual pipeline in [ADR 0005](0005-focus-companion-pivot.md): Home Screen Motion is no longer a per-Owner Cutout.

## Decision

Cat On Chair quality comes from one designed character with moving parts, not from swapping AI pose images. Dog Companion keeps a unique Source Photo, but the dog that climbs the chair is a **shared paper-cutout puppet**.

**Pipeline:** Source Photo → paper-cutout Comic Portrait → snap coat to a palette → tint bundled SpriteKit parts. No matting, no run/sit/back pose generation.

**Puppet:** Bundled PNG layers (fill, line, spots, eye), 3/4-side sitting facing upper-right. Idle breathes, nods, wags, blinks. Climb is the same parts, from in front of the chair up onto the seat.

**Furniture:** Every seat is a chair/sofa with back, seat, and front layers. The Companion starts in front of the front layer, then sits between back and front.

**Creation:** After Generation, the Owner sees the paper puppet (not only the portrait) and can correct the snapped coat before naming.

## Consequences

- `coatPaletteRaw` is the Motion identity. `cutoutData` is ignored.
- Comic Portrait style prompts are paper-cutout, not photoreal/anime polish.
- Matting remains in the target but is not on the Generation path.
- Personalization is coat and name, not body silhouette.
