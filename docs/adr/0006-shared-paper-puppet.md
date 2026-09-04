# ADR 0006: Owner cutout is scene identity; shared puppet is fallback

## Status

Accepted

Supersedes the earlier shared-puppet-as-identity decision in this file. Chair occlusion, front climb, and SpriteKit part motion from that work stay.

## Decision

The Owner must recognize the album dog at a glance on the Home Screen. Motion is the **Owner's sit Cutout**, sliced into head / body / legs / tail and driven in SpriteKit.

**Pipeline:** Source Photo → identity-preserving Comic Portrait (DashScope) → on-device Matting → sit Cutout. Coat palette is sampled but is not the scene identity.

**Fallback:** Bundled paper-puppet PNGs appear only when Cutout is missing (legacy Companion, remat in progress, or matting failure).

**Not in v1:** Extra AI sit/run/back pose images, HEVC, Pixi/Live2D/Spine/Rive, Metal mesh, high-frequency flipbook.

**Furniture:** Every seat is a chair/sofa with back, seat, and front layers. The Companion starts in front of the front layer, then sits between back and front.

**Creation:** After Generation, the Owner previews **their** sliced Cutout before naming.

## Consequences

- `cutoutData` is the Motion identity. Shared puppet textures are fallback only.
- Comic Portrait prompts must keep breed, face, ears, markings, and body — not a generic round paper dog.
- Matting is on the Generation path again.
- Personalization is the Cutout silhouette and markings, not a tinted shared body.
