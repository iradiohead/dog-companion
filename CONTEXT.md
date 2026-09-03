# Dog Companion

A virtual pet app where the Owner raises a Companion whose Comic Portrait is generated from a Source Photo of their real dog.

## Language

**Owner**:
The person using the app to care for their Companion. No account or login in MVP.
_Avoid_: User, account, player

**Companion**:
The virtual dog the Owner raises. One Companion per Owner in MVP. Has Vital Stats and a Comic Portrait.
_Avoid_: Pet, dog, avatar (when referring to the whole entity)

**Source Photo**:
A photograph of a real dog, taken with the camera or chosen from the photo library, used as input for Comic Portrait generation.
_Avoid_: reference image, input photo, original photo

**Comic Portrait**:
The stylized illustration of the Companion, generated from the Source Photo. Fixed after creation in MVP; may be replaced via Regeneration in a later version.
_Avoid_: avatar, cartoon image, manga image, 漫画形象

**Style Template**:
One of three preset visual styles applied during Comic Portrait generation. The Owner picks one before generation.
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

**Regeneration**:
Creating a new Comic Portrait from a new Source Photo, replacing the current one. Limited to 3 times per Companion. Available from the Home Screen.
_Avoid_: refresh, re-roll, redraw

**Vital Stats**:
The Companion's needs: Hunger and Mood in MVP. Health is deferred. Both decay passively over time while the app is closed.
_Avoid_: attributes, status bars, stats

**Hunger**:
A Vital Stat stored as 0–100. Decreased by Walk and passive decay (−20 every 4 hours). Increased by Feed.
_Avoid_: appetite, food level

**Mood**:
A Vital Stat stored as 0–100. Decreased by passive decay (−20 every 6 hours). Increased by Play and Walk.
_Avoid_: happiness, emotion

**Expression Tier**:
One of five UI bands mapped from a Vital Stat value: 81–100, 61–80, 41–60, 21–40, 0–20. Determines the Companion's visible expression on the Home Screen.
_Avoid_: mood level, stat level, emoji state

**Care Action**:
Something the Owner does to interact with the Companion. MVP has three: Feed, Play, and Walk.
_Avoid_: command, activity, task

**Feed**:
A Care Action that increases Hunger. Triggered by tapping a food icon.
_Avoid_: give food, eat

**Play**:
A Care Action that increases Mood. Triggered by tapping a toy icon with a simple animation.
_Avoid_: pet, interact

**Walk**:
A Care Action that increases Mood and decreases Hunger. Triggered by tapping a go-outside button.
_Avoid_: go for a walk, exercise

**Creation Flow**:
The onboarding sequence for a new Companion: pick Source Photo → pick Style Template → wait for Generation → name the Companion → enter the home screen.
_Avoid_: onboarding, setup wizard

**Generation**:
The one-time cloud process that produces a Comic Portrait from a Source Photo and Style Template. Result is cached locally; the Source Photo is not retained after generation in MVP. On failure, retries up to 2 times then returns the Owner to Source Photo selection.
_Avoid_: rendering, conversion, AI call

**Home Screen**:
The main screen shown when a Companion exists. Displays the Comic Portrait, Vital Stats, and Care Action buttons.
_Avoid_: main view, dashboard
