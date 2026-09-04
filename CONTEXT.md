# Dog Companion

A focus companion app where the Owner's real dog becomes an animated Companion that keeps them company during Focus Sessions — inspired by Cat On Chair, but personalized from a Source Photo.

## Language

**Owner**:
The person using the app to focus with their Companion. No account or login in MVP.
_Avoid_: User, account, player

**Companion**:
The Owner's virtual dog, generated from a Source Photo. One Companion per Owner in MVP. Has a Cutout, lives in a Scene, and animates during Focus Sessions.
_Avoid_: Pet, cat, avatar (when referring to the whole entity)

**Source Photo**:
A photograph of a real dog, taken with the camera or chosen from the photo library, used as input for Generation.
_Avoid_: reference image, input photo, original photo

**Comic Portrait**:
The stylized illustration produced during Generation, before background removal. An intermediate artifact; not the primary display asset on the Home Screen.
_Avoid_: avatar, cartoon image, manga image, 漫画形象

**Cutout**:
The transparent-background image of the Companion extracted from the Comic Portrait. The visual asset used for Motion on the Home Screen.
_Avoid_: sticker, sprite, matting result, 抠图

**Scene**:
The composed environment on the Home Screen: a bundled background illustration plus placed Furniture and Decor items.
_Avoid_: room, stage, environment

**Motion**:
The Companion's on-screen animation loop — idle breathing, jump-on-start, tap reactions — driven procedurally from the Cutout.
_Avoid_: animation, video, sprite sheet, GIF

**Style Template**:
One of three preset visual styles applied during Generation. The Owner picks one before Generation.
_Avoid_: filter, theme, art style

**Anime Style**:
A Style Template producing large eyes, soft lines, and Japanese animation aesthetics.
_Avoid_: manga style, 日系

**Flat Cartoon Style**:
A Style Template producing clean vector-like shapes similar to modern app illustration.
_Avoid_: Bitmoji style, 扁平

**Watercolor Style**:
A Style Template producing warm, hand-painted watercolor textures.
_Avoid_: painted style, 水彩

**Generation**:
The cloud pipeline that produces a Comic Portrait from a Source Photo and Style Template, then extracts a Cutout. Both are cached locally; the Source Photo is not retained after Generation completes.
_Avoid_: rendering, conversion, AI call

**Matting**:
The background-removal step within Generation that produces the Cutout from the Comic Portrait.
_Avoid_: segmentation,抠图, remove background

**Focus Session**:
A timed focus period (Pomodoro) during which the Companion appears in the Scene and keeps the Owner company. Completing a session may yield a Gift.
_Avoid_: timer, pomodoro, work session

**Gift**:
A collectible item the Companion leaves after a completed Focus Session. In MVP, Gifts directly unlock Furniture or Decor — there is no intermediate currency.
_Avoid_: reward, prize, loot

**Furniture**:
A placeable Scene item the Companion interacts with (e.g. a mat or cushion to jump onto). Some items are unlocked by completing Focus Sessions.
_Avoid_: decor, prop, item

**Decor**:
A cosmetic Scene item that does not affect Companion Motion (e.g. a plant, picture frame, carpet).
_Avoid_: decoration, ornament

**Regeneration**:
Re-running Generation from a new Source Photo, replacing the current Comic Portrait and Cutout. Limited to 3 times per Companion.
_Avoid_: refresh, re-roll, redraw

**Creation Flow**:
The onboarding sequence for a new Companion: pick Source Photo → pick Style Template → wait for Generation → name the Companion → enter the Home Screen.
_Avoid_: onboarding, setup wizard

**Home Screen**:
The main screen when a Companion exists. Displays the Scene with animated Cutout, Focus Session controls, and Furniture/Decor management.
_Avoid_: main view, dashboard
