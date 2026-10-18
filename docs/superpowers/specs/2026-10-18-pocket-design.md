# POCKET — Finger-drumming instrument and learning app

Design for review · 18 October 2026 · Working name, freely changeable

## Intended outcome

Build a native iPhone app delivered as an unsigned IPA. The app should make sustained, hands-on finger-drumming practice inviting and teach skills the player can use on a MIDI pad controller and when producing music in a DAW. The owner explicitly requests intensive pad interaction, real education, an exceptionally intuitive interface, and a working device build.

Assumptions for review: beginner through intermediate curriculum; hip-hop as the musical center, with transferable funk and electronic exercises; local-first storage; no account, subscription, or network requirement for lessons. iPhone first, with both portrait and landscape support. These are design decisions, not previously stated owner requirements. “State of the art” becomes measurable timing, multitouch, sound, feedback, and accessibility requirements below; “perfect” remains an aspiration subject to physical-device evaluation.

## Approach and tradeoffs

Recommended: one playable instrument shared by a structured course, focused practice tools, and free playing. It gives immediate usefulness while allowing lessons to fade their guidance and test independent playing.

Alternative: a note-highway rhythm game. It gives fast visual engagement, but would need separate exercises to establish recall, listening, groove construction, and hardware transfer.

Alternative: a complete miniature DAW with lessons. It provides deeper production workflows but increases navigation and implementation scope before the instrument and teaching are proven. POCKET will export performances rather than duplicate a full DAW.

## Main experience

Three destinations: **Learn**, **Practice**, **Play**. Settings are reached from a small toolbar control. Learn opens on one clear Continue action, with the next skill and a plain-language purpose. The course remains browsable and unlocked; recommendations do not prevent exploration.

The first session takes the player straight to four sounding pads, a brief pulse exercise, and one two-sound groove. Setup is optional. MIDI connection appears only when relevant. A short placement/technique explanation teaches relaxed hands, light rebound, and taking breaks when tense. The app must never pretend it can inspect posture or identify a particular finger from ordinary screen touches.

### The lesson screen

1. A short top line: lesson name, tempo, and pause.
2. A compact rhythm strip: beat numbers, current position, sound names, and optional suggested L/R sticking. No perspective or falling-note tunnel is needed to understand it.
3. A generous pad surface occupying most of the usable screen.
4. One immediate instruction: for example, “Keep the hats even. Add the snare on 2 and 4.”
5. A bottom action that reflects the current stage: Listen, Start, Retry, or Continue.

During playing, lesson browsing and bottom navigation withdraw from the pad area. Tempo and loop changes happen while paused or at an explicitly indicated next-bar boundary. No score animation interrupts playing. A stationary feedback marker shows Early / Center / Late; results after the phrase provide detail.

Visual direction: warm graphite background, off-white typography, restrained amber pulse, distinct instrument accents, generous spacing, and minimal chrome. Sound labels and symbols carry meaning alongside color. The experience should resemble a focused musical instrument. It must remain readable without constant glowing or animated backgrounds.

### Pad layouts

The complete instrument uses a stable 4×4 bank with pad numbering from bottom-left, consistent with common pad-controller orientation. A lesson can enlarge a subset into a labeled 2×2 or 4×2 teaching view; each cell retains its full-bank number so the relationship is explicit. Switching to the full bank never silently remaps sounds.

Initial sound map, editable and exportable:

| Row, top to bottom | Left | Center left | Center right | Right |
|---|---|---|---|---|
| 4 | Crash | Ride | High tom | Low tom |
| 3 | Percussion | Shaker | Clap | Rim |
| 2 | Soft snare | Snare | Open hat | Closed hat |
| 1 | Kick | Kick alternate | Closed hat alternate | Snare alternate |

Duplicate articulations allow two-handed patterns. MIDI Learn maps arbitrary controller notes to logical pads. Lessons refer to instrument roles, not hardcoded MIDI pitches. Left-handed mode mirrors optional sticking guidance; it does not silently rearrange a user's saved map. This is an original proposed teaching map, not a claim of a universal hardware standard.

The pad fires on touch-down, never touch release. Independent simultaneous touches must sound together. Holding a touch produces one strike; moving between pads does not accidentally retrigger in the default mode. Touch cancellation and app interruptions clear held visuals. Edge-safe spacing keeps system gestures away from the most-used pads. Pad hit areas stay at least 44 points, with larger playable targets wherever space permits. Compact landscape offers a full-screen pad view; lesson prose remains available while paused.

Phones do not provide reliable finger strike velocity equivalent to a hardware pad. Touch mode therefore offers fixed velocity and an explicitly labeled position-to-dynamics option. Neither is described as measuring force. Velocity technique assessments require velocity-capable MIDI input; touch users can audition separate soft/accent articulations without receiving a false hardware-dynamics certification.

## Teaching loop and feedback

Each lesson has an objective, countable written pattern, audible demonstration, suggested sticking where useful, common error, isolated practice step, combined phrase, memory test, and a creative transfer task.

The progression is **listen → isolate → combine → reduce prompts → recall → vary**. The player hears the target before attempting it. A one-bar count-in establishes the pulse. Practice can loop one or two bars, slow down without changing the drum timbre, solo a part, mute a demonstration part, and optionally wait for the correct pad. Wait mode is labeled untimed and never awards timing mastery.

Prompt fading removes pad flashes first, then the upcoming rhythm strip. An ear-only stage asks the player to echo a phrase. A silent-bar exercise removes the metronome temporarily, then reveals whether the pulse held. A creative task asks for an original variation while retaining a specific anchor, such as a backbeat. Open-ended improvisation is saved and replayable; the app does not pretend to grade artistic quality automatically.

### Initial course: 24 original lessons

| Unit | Lessons | Demonstrated skill |
|---|---|---|
| 1 · Find the pulse | 1. Relaxed rebound and quarter notes; 2. Eighth-note counting; 3. Kick and backbeat; 4. First two-bar groove | Count and play a stable pulse, then recover the downbeat |
| 2 · Share the work | 5. Alternating singles; 6. Kick-plus-hat unisons; 7. Steady hats with changing snare; 8. Changing kick under steady hats | Simultaneous strikes and independence exercises without rushing |
| 3 · Control subdivisions | 9. Count sixteenths; 10. Rest without losing time; 11. Offbeat kicks; 12. Triplet subdivision | Hear and place events between beats and preserve intentional silence |
| 4 · Shape the groove | 13. Accent versus ghost note; 14. Open/closed hat choke; 15. Straight versus swung eighths; 16. Deliberate laid-back snare | Distinguish an intended feel from inconsistent timing |
| 5 · Move between ideas | 17. Doubles; 18. RLRR LRLL orchestration; 19. One-beat fills; 20. Four-bar phrase with clean return | Change orchestration and return to beat one without accelerating |
| 6 · Make music | 21. Original boom-bap study; 22. Half-time hip-hop study; 23. Funk/electronic variation; 24. Memory and eight-bar performance | Play an arranged phrase, retain it without cues, and create a usable variation |

Every lesson needs a distinct pattern and explanation; changing only the title and tempo does not constitute a new lesson. Material is original. No commercial song recordings or copied paid lesson content are bundled. The dynamics lesson has separate touch audition and MIDI performance paths.

### Progress and intensive practice

Track completion, demonstrated tempo, timing spread, recall status, recent attempts, and the next concrete recommendation. A short daily session combines a warm-up, one difficult phrase, a memory retest, and free playing. The player can extend practice immediately. No life counter, punitive streak, or arbitrary waiting period interrupts it.

Default guided advancement requires three consecutive four-bar phrases with at least 90% target hits, no more than one extra strike per phrase, and median absolute timing error within the displayed level tolerance. This is an adjustable product criterion to validate, not a scientifically established mastery standard. Suggested initial tolerances: 70 ms for foundation, 50 ms for developing, 35 ms for precision. Matching windows must remain less than half the nearest same-role event spacing at the chosen tempo. Advanced dense exercises can require a slower tempo instead of overlapping match windows.

Two strong repetitions can suggest +3 BPM; a struggling phrase can suggest −5 BPM or an isolated part. The player controls these changes. Show one useful recommendation, such as “Your snare is consistently late; loop the backbeat at 65 BPM,” and retain the signed millisecond result. A left/right skill label is based on the exercise's intended sticking, not a claim that the phone verified hand identity.

## Timing and sound implementation

Use native Swift with SwiftUI for the surrounding application, a UIKit multitouch pad view, AVAudioEngine for sound, Core MIDI for controller input, and Codable local persistence. Keep these components small and concrete; no third-party UI/audio frameworks are necessary initially. Minimum deployment target proposed: iOS 17, with SDK compatibility verified during the macOS build.

Preload short, original or appropriately licensed drum samples before enabling playback. An always-running audio engine uses a bounded preallocated pool of voices; no sample-file reads occur on a hit. Per-voice gains avoid changing a shared voice's volume mid-decay. Open and closed hats share a choke group. Multiple samples/velocity layers and sensible output headroom avoid obvious machine-gun repetition and clipping. Two usable kits initially: dry electronic and warm hip-hop. Exported audio includes only assets with redistribution rights.

Request a low audio I/O buffer duration and read the actual negotiated duration and sample rate after activation. Preferred values are requests, not latency guarantees. Use the audio host/sample clock to schedule demonstrations and metronome in advance. UI refresh timers render position only; they do not drive audible timing. Record touch timestamps and MIDI host timestamps in one documented monotonic clock domain. The sound path starts independently of score rendering and persistence.

Calibrate a player's perceived alignment with a short tap-to-click procedure. Label this a personal timing offset estimate, because the result includes human anticipation as well as route behavior. Keep it separate from reported audio-route latency. Store offsets by route/input type, invalidate stale calibration after relevant changes, and offer reset. Bluetooth routes show a brief actionable suggestion to use the speaker or wired audio for precise practice. Route changes and interruptions pause the attempt and discard its mastery result; resumption includes a new count-in.

### Honest assessment

For each expected instrument event, store its musical beat, target articulation where assessable, and explicit feel offset. The target follows the chosen swing or laid-back timing, rather than always comparing against a straight grid. Match input one-to-one against pending events of the corresponding role within a bounded window, with deterministic nearest-event selection. One strike cannot score multiple notes. Simultaneous kick and hat remain separate expected events. Wrong-pad strikes count as extras; unmatched expected events become misses only after their late window closes. Late-window matching crosses bar boundaries correctly.

Show hit coverage, extra hits, signed timing bias, median absolute error, and timing variation separately. Avoid a single opaque score that rewards indiscriminate tapping. Dynamics scoring runs only with suitable input data. Recorded raw hits remain unquantized; optional quantization affects a separate playback/export copy only. Never label touchscreen input, end-to-end latency, hand independence, or sound quality as measured without corresponding evidence.

## Practice and free playing

Practice exposes tempo, subdivision, audible count, bar length, one/two-bar loop, prompt level, demonstration volume, and silent-bar metronome mode. Defaults remain simple; advanced controls sit in a sheet outside the strike area. Free Play opens the same instrument with optional metronome, a count-in, record/stop, replay, and a native share sheet.

Export a performance as Standard MIDI File with tempo metadata and the saved note map, plus a WAV render. Exported MIDI retains unquantized timing by default. Reopen a saved take and replay it against the same kit. Export errors preserve the take and offer retry. No full DAW, plugin host, generative beat service, or account system is required for this first app.

## Accessibility and resilience

Support Dynamic Type in teaching and navigation, VoiceOver pad labels and controls, high contrast, Reduce Motion, and redundant shape/text indicators. Dense explanations scroll outside active playing. Core actions remain accessible on a compact phone and large phone, with accessibility text sizes. Do not claim equivalent rapid performance through screen-reader interaction; provide a separate spoken/counting practice path and accessible controller setup.

Save completed attempts and takes atomically off the audio path. Backgrounding pauses teaching transport, cancels pending scheduling, and preserves completed work. MIDI disconnect pauses assessed practice; reconnect requires a deliberate restart. Handle audio-engine failure visibly with a recoverable retry, rather than silently recording strikes with no sound. Offline launches must load all bundled lessons and kits.

## Verification and IPA delivery

First deliverable after implementation: a genuine arm64 iPhone application packaged as `Payload/POCKET.app` inside an unsigned IPA. Build with code signing disabled using an actual macOS/Xcode SDK. An unsigned IPA still needs the owner's normal signing/sideloading method before installation. Never rename a source ZIP or simulator build to `.ipa`.

Build provenance includes the source commit, Xcode version, deployment target, artifact size, SHA-256, and build log. Inspect the app's Info.plist, arm64 Mach-O executable, bundled resources, package structure, and signing state before describing it as an unsigned device build. Stop short of claiming physical-device acceptance.

Meaningful checks: deterministic scoring cases for misses/extras/unisons/boundaries/swing/offsets and no double-credit; MIDI decoding and note-map behavior; persistence round trip; valid MIDI/WAV exports; actual device-target compilation. Simulator inspection covers first launch, first lesson, practice, free play, settings, compact/large layouts, and interrupted sessions when a simulator runner is available. Each validation stage has a ten-minute ceiling and reports its exact stopping point if exceeded. Produce the first IPA before extended validation.

Physical-device acceptance remains essential: rapid repeated strikes; simultaneous multi-finger input; audible latency and jitter; sustained playback without glitches; hat choking; route interruption/recovery; MIDI-controller hot-plug and velocity; both orientations; safe areas; accessibility layouts; exported takes opened in a DAW. The app cannot certify these properties from a successful compile alone.

## Build access and next decision

Observed in this session: the active execution machine is Linux with neither Swift nor Xcode available. The only listed Desktop Commander device is offline. The connected GitHub account can write repositories, but the available connector does not expose repository creation. `0BrokenByDefault0/owop` currently has a main branch containing only a six-byte README, so it is a possible host if the owner assigns it to this project.

Proposed repository action, pending review: use a new `codex/pocket-finger-drumming` branch in `0BrokenByDefault0/owop`, preserve main, add the native project and a macOS GitHub Actions device-build workflow triggered by branch pushes. Runner access and workflow-write permissions must be confirmed by actual execution. No merge is part of the proposal. If the owner prefers another repository, use that instead. Do not put this unrelated app in Aeon or VERT.

Implementation order after the required review: (1) native project, multitouch instrument, preloaded sound, and smoke build; (2) clock-driven transport and tested assessment; (3) all 24 lessons, progressive guidance, and saved progress; (4) MIDI Learn, dynamics path, recording and exports; (5) layout/accessibility checks, first unsigned IPA, then bounded post-IPA validation. Create a written implementation plan from this design before source implementation.

Status: design prepared for review; no product implementation, remote commit, workflow run, or IPA has been produced yet.

## Primary sources consulted

These sources ground general technique and platform decisions; the proposed product, lesson scripts, layouts, thresholds, and curriculum remain original design work.

- Melodics, [Beginners guide to Pads](https://support.melodics.com/en/articles/6782762-beginners-guide-to-pads): relaxed technique, rebound, and hand position.
- Melodics, [The Melodics Approach](https://support.melodics.com/en/articles/8051176-the-melodics-approach): orientation, chunking, tempo-focused practice, and evaluation.
- The Quest for Groove, [Finger Drumming Pad Layout](https://questforgroove.com/learnthis/pad-layout/) and [Let's hit the gym](https://questforgroove.com/course/lets-hit-the-gym/): consistent mapping, groove, bar awareness, and independence.
- Apple, [UITouch](https://developer.apple.com/documentation/UIKit/UITouch) and [timestamp](https://developer.apple.com/documentation/uikit/uitouch/timestamp): touch events, hardware-dependent force support, and event timing.
- Apple, [setPreferredIOBufferDuration](https://developer.apple.com/documentation/avfaudio/avaudiosession/setpreferrediobufferduration(_:)): requested versus actual audio buffer duration.
- Apple, [MIDIInputPortCreateWithProtocol](https://developer.apple.com/documentation/coremidi/midiinputportcreatewithprotocol(_:_:_:_:_:)): native MIDI input and callback threading.
