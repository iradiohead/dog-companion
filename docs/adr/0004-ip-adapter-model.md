# ADR 0004: Replicate IP-Adapter for Comic Portrait Generation

## Status

Accepted

## Context

Comic Portrait must preserve fur color and breed characteristics from the Source Photo while applying a Style Template. Generic text-to-image models cannot take a reference photo. Options on Replicate:

- **fofr/sdxl-ip-adapter** — reference image + prompt, good feature preservation
- **stability-ai/sdxl** img2img — prompt-driven, weaker likeness
- **tencentarc/photomaker** — optimized for human faces, poor on animals

## Decision

Use **fofr/sdxl-ip-adapter** (or successor IP-Adapter model on Replicate). Each Style Template maps to a distinct prompt:

| Style Template | Prompt direction |
|---|---|
| Anime Style | anime illustration, soft lines, expressive eyes |
| Flat Cartoon Style | flat vector cartoon, clean shapes, modern app illustration |
| Watercolor Style | watercolor painting, warm tones, hand-painted texture |

## Consequences

**Positive:**
- Best available balance of likeness and stylization for animal photos
- Single model, three prompts — simple to maintain

**Negative:**
- Model availability on Replicate may change — abstract behind `GenerationService`
- Results vary with photo quality; no breed selector fallback in MVP
