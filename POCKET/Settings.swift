import SwiftUI

struct SettingsView:View {
    @ObservedObject var s:Session
    @Environment(\.dismiss) private var dismiss
    @State private var offset=0.0
    var body:some View {
        NavigationStack {
            Form {
                Section("Audio") {
                    Label(s.audioReady ? "Instrument ready":"Audio unavailable",systemImage:s.audioReady ? "checkmark.circle":"exclamationmark.circle")
                    Text(s.audioDescription).font(.footnote).foregroundStyle(.secondary)
                    Text(String(format:"Route-reported output latency: %.1f ms. This is not a measurement of total touch-to-sound latency.",s.audio.latencyMs)).font(.caption).foregroundStyle(.secondary)
                    if s.audio.wireless {Text("For precise practice, use the speaker or wired audio. This wireless route can add delay.").font(.footnote).foregroundStyle(Ink.accent)}
                    Button("Retry audio") {s.stop();s.prepareAudio()}
                    Picker("Kit",selection:$s.kit) {Text("Original Dry").tag(0);Text("Original Warm").tag(1)}
                    Text("Both kits are synthesized specifically for POCKET. Sound generation is precomputed; the audio render callback reads bounded voices without file access.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Timing alignment") {
                    Text("Tap with the click to estimate a comfortable scoring offset for this route. This includes your own tapping tendency; it does not measure hardware latency.").font(.footnote).foregroundStyle(.secondary)
                    if s.calibrating {
                        Text("Tap the kick on each click · \(s.calibrationCount) taps")
                        CalibrationPad(s:s).frame(height:125)
                        Button("Cancel alignment") {s.stop()}
                    } else {Button("Align my taps") {s.beginCalibration()}}
                    HStack {Text("Offset");Spacer();Text(String(format:"%+.0f ms",offset)).monospacedDigit()}
                    Slider(value:$offset,in:-200...200,step:1).accessibilityLabel("Scoring offset in milliseconds").onChange(of:offset) {_,value in s.setOffset(value)}
                    Button("Reset alignment") {offset=0;s.setOffset(0)}
                }
                Section("Touch and guidance") {
                    Toggle("Position dynamics",isOn:$s.positional)
                    Text("Off: consistent loudness. On: a strike near the top is louder. Position is a deliberate control, not measured finger force.").font(.footnote).foregroundStyle(.secondary)
                    Toggle("Mirror hand suggestions",isOn:$s.leftHand)
                    Text("L/R markers suggest a hand; the phone cannot identify which finger or hand you actually used. For two-handed patterns, place the phone on a stable surface and use relaxed rebound.").font(.footnote).foregroundStyle(.secondary)
                }
                Section("MIDI controller") {
                    Label(s.midiStatus,systemImage:s.midiConnected ? "pianokeys":"cable.connector")
                    Text("Connect a class-compliant USB MIDI pad controller using a suitable adapter. Select a sound below, then strike the hardware pad to map it.").font(.footnote).foregroundStyle(.secondary)
                    if let pad=s.learnPad {Text("Listening for a note → \(DrumPad.all[pad].name)").foregroundStyle(Ink.accent);Button("Cancel MIDI Learn"){s.learnPad=nil}}
                    ForEach(DrumPad.all) {pad in
                        Button {s.learnPad=pad.id} label:{HStack {Text("\(pad.id+1). \(pad.name)");Spacer();Text(s.noteMap.filter{$0.value==pad.id}.keys.sorted().map(String.init).joined(separator:", ")).font(.caption.monospaced()).foregroundStyle(.secondary)}}
                    }
                }
                Section("Practice that transfers") {
                    Text("Keep your hands relaxed. Count through rests. Learn a phrase slowly, remove the guide, and make a small original variation. Hardware pads add physical rebound and strike dynamics that glass cannot reproduce.")
                    Text("No account required. Lessons and original sounds work offline. Your progress and latest 50 takes stay on this device.").font(.footnote).foregroundStyle(.secondary)
                    Text("POCKET 1.0 · Native finger-drumming practice").font(.caption).foregroundStyle(.secondary)
                }
            }.navigationTitle("Your instrument").toolbar {ToolbarItem(placement:.confirmationAction){Button("Done"){s.stop();dismiss()}}}
        }.tint(Ink.accent).onAppear {offset=s.offsetMs}.onChange(of:s.calibrating){_,active in if !active {offset=s.offsetMs}}.onDisappear{s.learnPad=nil;if s.calibrating {s.stop()}}
    }
}
struct CalibrationPad:UIViewRepresentable {
    @ObservedObject var s:Session
    func makeUIView(context:Context)->PadView {let v=PadView();v.pads=[0];return v}
    func updateUIView(_ view:PadView,context:Context) {view.pads=[0];view.onHit={pad,velocity,time in s.strike(pad,velocity:velocity,timestamp:time)};view.last=s.lastHitTime>AudioEngine.now-0.1 ? s.lastPad:-1;view.setNeedsDisplay()}
}
