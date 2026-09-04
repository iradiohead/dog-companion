# Dog Companion

A focus companion app where the Owner's real dog becomes an animated Companion that keeps them company during Focus Sessions — inspired by Cat On Chair, but personalized from a Source Photo.

## Language

**Owner**:
The person using the app to focus with their Companion. No account or login in MVP.
_Avoid_: User, account, player

**Companion**:
The Owner's virtual dog. One Companion per Owner in MVP. Has a Comic Portrait, a Coat Palette, and a shared Puppet that lives in a Scene during Focus Sessions.
_Avoid_: Pet, cat, avatar (when referring to the whole entity)

**Source Photo**:
A photograph of a real dog, taken with the camera or chosen from the photo library, used as input for Generation.
_Avoid_: reference image, input photo, original photo

**Comic Portrait**:
The paper-cutout illustration produced during Generation. Shown in Creation so the Owner recognizes their dog; not the asset that climbs the chair.
_Avoid_: avatar, cartoon image, manga image, 漫画形象

**Coat Palette**:
One of six snapped coat colors (black, brown, white, orange, gray, spotted) sampled from the Comic Portrait and applied to the shared Puppet.
_Avoid_: theme color, tint only

**Puppet**:
The bundled paper-cutout dog (fill, line, spots, eye layers) rendered in SpriteKit. All Owners share the same parts; only the Coat Palette changes.
_Avoid_: cutout, sticker, sprite sheet

**Cutout**:
Legacy transparent image from matting. Not used for Motion. Ignored if still stored on a Companion.
_Avoid_: sticker, sprite, matting result, 抠图

**Scene**:
The composed environment on the Home Screen: a bundled background illustration plus placed Furniture and Decor items.
_Avoid_: room, stage, environment

**Motion**:
The Companion's on-screen animation — idle breathing/blink/tail, and climbing onto layered Furniture — driven by the Puppet, not by swapping images.
_Avoid_: animation, video, sprite sheet, GIF

**Style Template**:
One of three preset visual styles applied during Generation. The Owner picks one before Generation.
_Avoid_: filter, theme, art style

**Anime Style**:
A Style Template producing round paper-cutout dogs.
_Avoid_: manga style, 日系

**Flat Cartoon Style**:
A Style Template producing more geometric paper cutouts.
_Avoid_: Bitmoji style, 扁平

**Watercolor Style**:
A Style Template producing crayon-textured paper cutouts.
_Avoid_: painted style, 水彩

**Generation**:
The cloud pipeline that produces a paper-cutout Comic Portrait from a Source Photo and Style Template, then snaps a Coat Palette. The Source Photo is not retained after Generation completes.
_Avoid_: rendering, conversion, AI call

**Matting**:
Legacy background-removal. Not part of Generation anymore.
_Avoid_: segmentation,抠图, remove background

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
Re-running Generation from a new Source Photo, replacing the Comic Portrait and Coat Palette. Limited to 3 times per Companion.
_Avoid_: refresh, re-roll, redraw

**Creation Flow**:
The onboarding sequence for a new Companion: pick Source Photo → pick Style Template → wait for Generation → preview the Puppet and correct coat → name the Companion → enter the Home Screen.
_Avoid_: onboarding, setup wizard

**Home Screen**:
The main screen when a Companion exists. Displays the Scene with the animated Puppet, Focus Session controls, and Furniture/Decor management.
_Avoid_: main view, dashboard
