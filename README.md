# POCKET

Native iPhone finger-drumming instrument and 24-lesson course. Built with SwiftUI, UIKit multitouch pads, AVAudioEngine, Core MIDI, and a small C++ audio/assessment kernel. No app dependencies, account, or online lesson service.

## Use it

- **Learn:** start with pulse and backbeat; progress through subdivisions, hand independence exercises, ghost notes, swing, fills, and an eight-bar performance. Each lesson explains the movement, counts the pattern, and gives a creative transfer exercise.
- **Practice:** listen, isolate a sound, choose one/two/four/eight bars, slow down, reduce prompts, practice from memory, echo a phrase, use untimed wait mode, or hold the pulse through silent metronome bars.
- **Play:** record up to two minutes, listen back, and share raw-timed MIDI or a stereo WAV. The latest 50 takes remain on-device.
- **Settings:** audio recovery, per-route timing alignment, optional position dynamics, and USB MIDI Learn.

Three full phrases with at least 90% target hits, no more than one extra strike per phrase, and the lesson's displayed median-error threshold demonstrate a stable skill. Memory practice is tracked separately. Touch mode measures timing, not finger force or hand identity. A velocity-sensitive MIDI controller enables actual dynamics input.

The 16-pad map remains stable across enlarged focus view and full-bank view. Two original synthesized kits use three velocity layers, two round-robin variants per layer, 96 bounded voices, and sample-offset open/closed-hat choking. Samples are precomputed before playback; the render callback performs no allocation, locking, or file access. Actual device latency still requires measurement.

## Build

On macOS with Xcode:

```sh
python3 scripts/project.py
xcodebuild -project POCKET.xcodeproj -scheme POCKET -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build/device CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
python3 scripts/verify_ipa.py
```

The artifact is `build/artifacts/POCKET-1.0-unsigned.ipa`, a generic arm64 iPhone build with a `Payload/POCKET.app` layout. It must be signed with the owner's sideloading method before installation. The branch's GitHub Actions workflow uploads the IPA before extended validation. Each validation stage has a 600-second limit.

## Checks

```sh
g++ -std=c++17 -O2 -pthread POCKET/Core/PocketCore.cpp Tests/core_tests.cpp -o /tmp/pocket-core
/tmp/pocket-core
```

After producing the IPA, CI checks course uniqueness and event validity, scoring policy, running-status/SysEx parsing, raw MIDI note mapping, WAV output, take persistence and backup recovery. It then builds the native simulator app, exercises lesson navigation, recording/replay and landscape pad dimensions with XCTest, and captures native screens.

Physical multitouch feel, audible latency, controller hot-plug behavior, hardware velocity, long-session audio stability and accessibility interaction require physical-device review. A compiled IPA or simulator check is not physical-device acceptance.

The approved design and implementation plan are in `docs/superpowers/`. Work is isolated on `codex/pocket-finger-drumming`; no merge is part of delivery.
