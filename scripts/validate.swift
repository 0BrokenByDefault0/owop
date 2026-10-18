import Foundation
@main struct Validation {
    static func main() throws {
        precondition(Lesson.all.count==24)
        precondition(Set(Lesson.all.map(\.title)).count==24)
        precondition(Set(Lesson.all.map{String(describing:$0.notes)}).count==24)
        for lesson in Lesson.all {
            precondition(!lesson.notes.isEmpty && !lesson.instruction.isEmpty && !lesson.transfer.isEmpty)
            precondition(lesson.notes.allSatisfy{$0.beat>=0 && $0.beat<Double(lesson.bars*4) && (0..<16).contains($0.pad)})
        }
        precondition(Lesson.all[23].bars==8)
        let take=Take(title:"Validation",bpm:80,kit:0,duration:1.1,hits:[PlayedHit(time:0,pad:0,velocity:0.8,midi:true),PlayedHit(time:0,pad:7,velocity:0.5,midi:true),PlayedHit(time:0.375,pad:5,velocity:0.9,midi:true)])
        let midi=TakeExporter.midi(take)
        precondition(String(data:midi.prefix(4),encoding:.ascii)=="MThd")
        precondition(Array(midi[12..<14])==[1,224])
        precondition(midi.suffix(4)==Data([0,255,47,0]))
        let wave=try TakeExporter.wav(take)
        precondition(String(data:wave.prefix(4),encoding:.ascii)=="RIFF")
        precondition(String(data:wave[8..<12],encoding:.ascii)=="WAVE")
        precondition(wave.count>100000 && wave.dropFirst(44).contains{$0 != 0})
        let data=try JSONEncoder().encode(SavedState(progress:[0:ProgressRecord(attempts:1)],takes:[take]))
        let restored=try JSONDecoder().decode(SavedState.self,from:data)
        precondition(restored.takes.count==1 && restored.takes[0].hits.count==3 && restored.progress[0]?.attempts==1)
        try FileManager.default.createDirectory(atPath:"build/validation",withIntermediateDirectories:true)
        try midi.write(to:URL(fileURLWithPath:"build/validation/check.mid"))
        try wave.write(to:URL(fileURLWithPath:"build/validation/check.wav"))
        print("PASS: 24 distinct lessons, valid events, eight-bar performance, native MIDI/WAV render, unquantized take persistence")
    }
}
