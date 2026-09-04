# Dog Companion

A focus companion app where the Owner's real dog becomes an animated Companion that keeps them company during Focus Sessions — inspired by Cat On Chair, but personalized from a Source Photo.

## Language

**Owner**:
The person using the app to focus with their Companion. No account or login in MVP.
_Avoid_: User, account, player

**Companion**:
The Owner's virtual dog. One Companion per Owner in MVP. Has a Comic Portrait and a Cutout that lives in a Scene during Focus Sessions. Must be recognizable as the Source Photo dog at a glance.
_Avoid_: Pet, cat, avatar (when referring to the whole entity)

**Source Photo**:
A photograph of a real dog, taken with the camera or chosen from the photo library, used as input for Generation.
_Avoid_: reference image, input photo, original photo

**Comic Portrait**:
The stylized illustration produced during Generation. Must keep the Source Photo dog's breed, face, ears, markings, and body. Input to Matting.
_Avoid_: avatar, cartoon image, manga image, 漫画形象

**Coat Palette**:
One of six snapped coat colors sampled from the Comic Portrait. Stored, but not the Home Screen identity.
_Avoid_: theme color, tint only

**Puppet**:
Bundled paper-dog PNG layers used only when a Cutout is missing (legacy Companion, remat in progress, or matting failure).
_Avoid_: shared character, generic dog

**Cutout**:
The transparent sit image from Matting. This is the Motion display asset: sliced into head / body / legs / tail and driven in SpriteKit.
_Avoid_: sticker, sprite, 抠图 (in Owner-facing copy)

**Scene**:
The composed environment on the Home Screen: a bundled background illustration plus placed Furniture and Decor items.
_Avoid_: room, stage, environment

**Motion**:
The Companion's on-screen animation — idle breathing/tail, and climbing onto layered Furniture — driven by moving parts of the Cutout, not by swapping AI pose images.
_Avoid_: animation, video, sprite sheet, GIF

**Style Template**:
One of three preset visual styles applied during Generation. The Owner picks one before Generation. Style must not replace the dog's identity.
_Avoid_: filter, theme, art style

**Anime Style**:
A Style Template producing a Japanese-illustration look of the Source Photo dog.
_Avoid_: manga style, generic chibi mascot

**Flat Cartoon Style**:
A Style Template producing a flat-illustration look of the Source Photo dog.
_Avoid_: Bitmoji style, generic icon dog

**Watercolor Style**:
A Style Template producing a watercolor look of the Source Photo dog.
_Avoid_: painted style that invents a different dog

**Generation**:
The pipeline that produces a Comic Portrait from a Source Photo and Style Template, then Mattes it into a Cutout. The Source Photo is not retained after Generation completes.
_Avoid_: rendering, conversion, AI call

**Matting**:
On-device background removal that produces the Cutout used on the Home Screen.
_Avoid_: segmentation, remove background (in Owner-facing copy)

**Focus Session**:
A timed focus period (Pomodoro) during which the Companion appears in the Scene and keeps the Owner company. Completing a session may yield a Gift.
_Avoid_: timer, pomodoro, work session

**Gift**:
A collectible item the Companion leaves after a completed Focus Session. In MVP, Gifts directly unlock Furniture or Decor — there is no intermediate currency.
_Avoid_: reward, prize, loot

**Furniture**:
A placeable Scene item the Companion climbs onto. Each item is a chair or sofa with back, seat, and front layers. Some items are unlocked by completing Focus Sessions.
_Avoid_: decor, prop, item

**Decor**:
A cosmetic Scene item that does not affect Companion Motion (e.g. a plant, picture frame, carpet).
_Avoid_: decoration, ornament

**Regeneration**:
Re-running Generation from a new Source Photo, replacing the Comic Portrait and Cutout. Limited to 3 times per Companion.
_Avoid_: refresh, re-roll, redraw

**Creation Flow**:
The onboarding sequence for a new Companion: pick Source Photo → pick Style Template → wait for Generation → preview the Owner's Cutout → name the Companion → enter the Home Screen.
_Avoid_: onboarding, setup wizard

**Home Screen**:
The main screen when a Companion exists. Displays the Scene with the animated Cutout, Focus Session controls, and Furniture/Decor management.
_Avoid_: main view, dashboard
