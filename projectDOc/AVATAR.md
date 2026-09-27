# Avatar — "Aura" Reference Plan

Reference: an anime-style 3D companion avatar with distinct visual states —
idle intro, listening, thinking, speaking (with voice + animation), real-time
facial expressions, and continuous conversation. Two build paths, ranked by
feasibility for your timeline.

## Path A — Pre-rendered clip swapping (RECOMMENDED for v1)

Most polished companion-app demos are **not** real-time 3D — they swap short
looping video clips based on app state. This gets you the exact visual
quality of the reference without any real-time rigging/rendering engineering.

### What you need
- 5–6 short looping clips of the same character, one per state:
  1. `idle.mp4` — default breathing/blink loop (shown on home screen)
  2. `listening.mp4` — attentive pose, mic-active look
  3. `thinking.mp4` — looking up/pondering loop
  4. `speaking.mp4` — talking + hand gesture loop (can have 2–3 variants for variety)
  5. `reacting.mp4` — optional, positive reaction (heart eyes, thumbs up, etc.)

### Where to get the clips
- Commission a short anime-style looping animation from a freelancer (Fiverr/Upwork) — cheapest, most control over exact style
- Or generate short clips with an AI video tool, then loop them cleanly
- Keep each clip 2–4 seconds, seamlessly loopable, transparent or fixed background matching your app theme

### Flutter wiring
```dart
enum AvatarState { idle, listening, thinking, speaking, reacting }

// video_player package, one controller per clip (or swap source on state change)
class AvatarWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationProvider).avatarState;
    return VideoPlayerWidget(clipForState(state)); // loops automatically
  }
}
```
Package: `video_player` (+ `chewie` optional for easier looping control).

### Why this is the right v1 choice
Ships in days, matches the reference's visual bar exactly, and the "3D
feel" comes from the pre-rendered quality of the clips, not from your app
doing real-time rendering. Zero rigging/shader work on your end.

---

## Path B — True real-time 3D (v2 / stretch goal)

Only pursue after Path A is shipped and working end-to-end.

### Character
- **VRoid Studio** (free) — build an anime-style 3D character, export as `.vrm`
- `.vrm` format ships with built-in blendshapes for expressions and mouth shapes — exactly what's needed for lip sync and the "real-time facial expressions" state in the reference

### Rendering in Flutter
- `three-vrm` (Three.js) rendered inside a Flutter WebView, driven via a JS bridge, OR
- `flutter_unity_widget` if you'd rather work in Unity directly

### Driving states/expressions
- Map `AvatarState` (idle/listening/thinking/speaking/reacting) to blendshape presets already built into the `.vrm` format (`joy`, `angry`, `sorrow`, mouth shapes `aa`/`ih`/`ou`/`ee`/`oh`)
- Feed mouth blendshapes from ElevenLabs viseme timestamps for accurate lip sync during speaking

### Effort
Multi-week — rigging, WebView/Unity bridge, blendshape wiring, and debugging cross-platform rendering are each nontrivial. Budget this only if you have spare time before interviews.

---

## Decision

Build **Path A** first, ship it, then decide if Path B is worth the time
investment based on what's left before placement season.
