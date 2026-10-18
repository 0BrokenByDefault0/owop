import Foundation

struct DrumPad: Identifiable {
    let id: Int
    let name: String
    let short: String
    let role: Int
    static let all: [DrumPad] = [
        .init(id:0,name:"Kick",short:"KICK",role:0), .init(id:1,name:"Kick alternate",short:"KICK II",role:0),
        .init(id:2,name:"Hi-hat alternate",short:"HAT II",role:2), .init(id:3,name:"Snare alternate",short:"SNARE II",role:1),
        .init(id:4,name:"Ghost snare",short:"GHOST",role:1), .init(id:5,name:"Snare",short:"SNARE",role:1),
        .init(id:6,name:"Open hi-hat",short:"OPEN HAT",role:3), .init(id:7,name:"Closed hi-hat",short:"HI-HAT",role:2),
        .init(id:8,name:"Percussion",short:"PERC",role:4), .init(id:9,name:"Shaker",short:"SHAKER",role:5),
        .init(id:10,name:"Clap",short:"CLAP",role:6), .init(id:11,name:"Rim",short:"RIM",role:7),
        .init(id:12,name:"Crash",short:"CRASH",role:8), .init(id:13,name:"Ride",short:"RIDE",role:9),
        .init(id:14,name:"High tom",short:"HI TOM",role:10), .init(id:15,name:"Low tom",short:"LOW TOM",role:11)
    ]
    static func primary(_ role: Int) -> Int { [0,5,7,6,8,9,10,11,12,13,14,15][max(0,min(11,role))] }
}
struct Note: Codable, Equatable {
    var beat: Double
    var pad: Int
    var velocity: Float = 0.8
    var hand: String? = nil
    var role: Int { DrumPad.all[pad].role }
}
struct Lesson: Identifiable {
    let id: Int
    let title: String
    let purpose: String
    let instruction: String
    let count: String
    let mistake: String
    let transfer: String
    let bpm: Int
    let bars: Int
    let notes: [Note]
    var unit: Int { id / 4 }
    var unitName: String { Self.units[unit] }
    var tolerance: Double { unit<2 ? 70 : (unit<4 ? 50 : 35) }
    var pads: [Int] { Array(Set(notes.map(\.pad))).sorted() }
    static let units = ["Find the pulse", "Share the work", "Control subdivisions", "Shape the groove", "Move between ideas", "Make music"]
    static let all: [Lesson] = {
        let titles=["Your first pulse","Split the beat","Kick & backbeat","A groove of your own","Two hands, one pulse","Together on the one","Independent backbeat","Move the kick","Sixteenth-note map","The power of silence","Offbeat kicks","Three inside one","Soft & strong","Open, then close","Learn the swing","Behind the beat","Make your doubles even","The paradiddle","A fill that fits","Find your way home","The boom-bap pocket","Half-time weight","A different kind of bounce","Play it from memory"]
        let purpose=["Find a comfortable rebound and a steady beat.","Hear the space halfway between each pulse.","Feel the snare on beats two and four.","Connect kick, snare, and hats into music.","Share repeated notes between your hands.","Land two sounds at the same instant.","Keep one part steady while another changes.","Place the kick independently of the hats.","Know where every sixteenth belongs.","Leave a gap without losing the pulse.","Make the spaces between beats feel intentional.","Fit three even notes inside each beat.","Give a phrase shape using contrast.","Use a closed hat to cut an open hat short.","Hear long-short pairs instead of even pairs.","Lay the snare back while the pulse stays centered.","Play two notes evenly before changing hands.","Turn RLRR LRLL into a musical phrase.","Finish a short fill without rushing.","Keep your place through a four-bar phrase.","Build weight with a kick and a strong backbeat.","Hold a slow backbeat over a faster hat pulse.","Keep the groove when the sound and spacing change.","Remember, vary, and perform an eight-bar arrangement."]
        let instructions=["Tap the kick on 1, 2, 3, 4. Keep your hand loose; let the finger rebound.","Count 1 & 2 & 3 & 4 &. Play every syllable on the hat.","Kick on 1 and 3. Snare on 2 and 4. Say the numbers aloud.","Keep eighth-note hats moving. Add kick on 1 and 3, snare on 2 and 4.","Alternate L R on the hats. The app suggests a sticking; you verify which fingers you use.","Play kick and hat together on 1 and 3. Neither sound should lead.","Keep hats on the beat. Place the snare on 2 and the & of 4.","Keep hats even. Move the second kick to the & of 3.","Count 1 e & a, 2 e & a. Use two fingers to keep the notes even.","Count every eighth aloud, including the spaces where you do not play.","Keep the backbeat fixed. Kick on 1, the & of 2, and the & of 3.","Say 1-trip-let, 2-trip-let. Keep all three equally spaced.","Listen to the soft snare between the loud backbeats. Touch uses a separate ghost pad; MIDI can test velocity.","An open hat on the & of 4 leads into a closed hat on the next 1.","The & arrives two-thirds of the way through the beat. Keep the numbered beats centered.","The snare target is 35 ms behind 2 and 4. Hats and kick stay centered.","Use LL RR on the hats. Make the second tap as even as the first.","Play R L R R, L R L L. Split the colors between snare and hat.","Play the groove for three beats; fill across beat 4, then return to 1.","Listen to all four bars. A fill marks the last bar, then the downbeat returns.","Listen for the offbeat kick and quieter snare. Keep the backbeat steady.","Snare on 3. Hats play eighths. Do not accidentally double the backbeat.","The kick stays on each beat. Clap and offbeat hats create the movement.","Play the phrase, remove the guide, then make one change that keeps the backbeat intact."]
        let mistakes=["A long press is not a second strike. Lift and rebound.","Keep the & exactly halfway; avoid rushing the second half.","Keep counting through the snare instead of restarting on it.","Do not stop the hat when the snare arrives.","Stay relaxed; speed is a result of even movement.","Listen for a single combined attack, not a quick flam.","Do not let a moved snare drag the hats with it.","The hats are your anchor while the kick moves.","Slowing down is more useful than squeezing four notes in.","A rest has a counted duration. It is not a pause in the clock.","Return cleanly to the next numbered beat.","Do not turn the last two notes into an uneven rush.","A ghost note is quiet, not randomly late.","Avoid a gap between the open hat and its closing strike.","Swing changes the subdivision, not the length of the bar.","Consistently late is different from unpredictably late.","The second note should not collapse into the first.","Count continuously while the leading hand changes.","The fill must end in time for beat one.","Do not speed up when the last bar gets busier.","Keep the quiet hits subordinate to the backbeat.","Half-time is a feel, not an excuse to lose the inner pulse.","New sounds should not change your timing.","If recall fails, listen again and rebuild one bar at a time."]
        return titles.indices.map { id in
            let bars=id==23 ? 8 : 4
            var notes=[Note]()
            for bar in 0..<bars {
                let base=Double(bar*4)
                func add(_ pad:Int,_ beats:[Double],_ vel:Float=0.8) { notes += beats.map { Note(beat:base+$0,pad:pad,velocity:vel) } }
                switch id {
                case 0: add(0,[0,1,2,3])
                case 1: add(7,stride(from:0.0,to:4.0,by:0.5).map{$0})
                case 2: add(0,[0,2]);add(5,[1,3])
                case 3: add(7,stride(from:0.0,to:4.0,by:0.5).map{$0});add(0,[0,2]);add(5,[1,3])
                case 4: for i in 0..<8 { add(i%2==0 ? 2:7,[Double(i)*0.5]) }
                case 5: add(0,[0,2]);add(7,[0,1,2,3])
                case 6: add(7,[0,0.5,1,1.5,2,2.5,3,3.5]);add(5,[1,3.5])
                case 7: add(7,[0,0.5,1,1.5,2,2.5,3,3.5]);add(0,[0,2.5]);add(5,[1,3])
                case 8: for i in 0..<16 { add(i%2==0 ? 2:7,[Double(i)/4]) }
                case 9: add(7,[0,0.5,1.5,2,3,3.5]);add(0,[0,2]);add(5,[1,3])
                case 10: add(7,[0,0.5,1,1.5,2,2.5,3,3.5]);add(0,[0,1.5,2.5]);add(5,[1,3])
                case 11: for i in 0..<12 { add(i%2==0 ? 2:7,[Double(i)/3]) }
                case 12: add(7,[0,0.5,1,1.5,2,2.5,3,3.5],0.6);add(0,[0,2]);add(5,[1,3],0.9);add(4,[1.75,2.75],0.3)
                case 13: add(7,[0,0.5,1,1.5,2,2.5,3]);add(6,[3.5]);add(0,[0,2]);add(5,[1,3])
                case 14: add(7,[0,2.0/3,1,1+2.0/3,2,2+2.0/3,3,3+2.0/3]);add(0,[0,2]);add(5,[1,3])
                case 15: add(7,[0,0.5,1,1.5,2,2.5,3,3.5]);add(0,[0,2]);add(5,[1,3])
                case 16: for i in 0..<16 { add((i/2)%2==0 ? 2:7,[Double(i)/4]) }
                case 17: let sticking=[5,7,5,5,7,5,7,7];for i in 0..<16 { add(sticking[i%8],[Double(i)/4]) }
                case 18: add(7,[0,0.5,1,1.5,2,2.5]);add(0,[0,2]);add(5,[1,3,3.25]);add(14,[3.5]);add(15,[3.75])
                case 19: add(7,bar==3 ? [0,0.5,1,1.5,2,2.5]:[0,0.5,1,1.5,2,2.5,3,3.5]);add(0,[0,2]);add(5,bar==3 ? [1,3,3.25]:[1,3]);if bar==3 {add(14,[3.5]);add(15,[3.75])}
                case 20: add(7,[0,0.5,1,1.5,2,2.5,3,3.5],0.6);add(0,bar%2==0 ? [0,1.5,2.5]:[0,2,2.75]);add(5,[1,3],0.9);add(4,[2.75],0.3)
                case 21: add(7,[0,0.5,1,1.5,2,2.5,3,3.5],0.65);add(0,[0,1.5,3.5]);add(5,[2],0.9)
                case 22: add(0,[0,1,2,3]);add(10,[1,3]);add(7,[0.5,1.5,2.5,3.5],0.65);add(9,[0,1,2,3],0.35)
                default: add(7,bar%4==3 ? [0,0.5,1,1.5,2,2.5]:[0,0.5,1,1.5,2,2.5,3,3.5],0.65);add(0,bar%2==0 ? [0,2.5]:[0,1.5,2]);add(5,bar%4==3 ? [1,3,3.25]:[1,3],0.9);if bar%4==3 {add(14,[3.5]);add(15,[3.75])}
                }
            }
            for index in notes.indices {
                if [4,8,11,16].contains(id) { notes[index].hand=notes[index].pad==2 ? "L":"R" }
                if id==17 { notes[index].hand=notes[index].pad==5 ? "R":"L" }
            }
            return Lesson(id:id,title:titles[id],purpose:purpose[id],instruction:instructions[id],count:id==11 ? "1 trip let · 2 trip let · 3 trip let · 4 trip let" : (id==8||id==16||id==17 ? "1 e & a · 2 e & a · 3 e & a · 4 e & a":"1 & · 2 & · 3 & · 4 &"),mistake:mistakes[id],transfer:id<4 ? "Close the guide and play the same pulse on a table. Then return to the pads without changing tempo." : (id<12 ? "Keep the anchor part and invent one new placement for the other sound. Record it in Play." : (id<20 ? "Use this technique in a different groove. Keep four bars steady before adding a variation.":"Record an eight-bar take, export the MIDI to your DAW, and build a musical idea around your own performance.")),bpm:id<4 ? 65:(id==21 ? 110:80),bars:bars,notes:notes.sorted { $0.beat < $1.beat })
        }
    }()
}

struct PlayedHit: Codable, Sendable {
    var time: Double
    var pad: Int
    var velocity: Float
    var midi: Bool
    var sourceNote: Int? = nil
    var assessmentTime: Double? = nil
}
struct Take: Codable, Identifiable, Sendable {
    var id=UUID()
    var date=Date()
    var title: String
    var bpm: Int
    var kit: Int
    var duration: Double
    var hits: [PlayedHit]
    var padNotes: [Int]? = nil
}
struct ProgressRecord: Codable {
    var attempts=0
    var bestBPM=0
    var bestCoverage=0.0
    var recalled=false
    var consecutive=0
    var completed=false
}
struct SavedState: Codable {
    var progress: [Int:ProgressRecord]=[:]
    var takes: [Take]=[]
}
struct PracticeResult {
    var hits:Int, extras:Int, misses:Int
    var bias:Double, median:Double, spread:Double, velocityError:Double
    var total:Int
    var passed:Bool
    var assessed:Bool
    var velocityAssessed:Bool
    var coverage:Double { total==0 ? 0:Double(hits)/Double(total) }
    var suggestion:String {
        if !assessed { return "Untimed practice builds the movement. Try Guided when the pattern feels familiar." }
        if coverage<0.75 { return "Listen once more, then isolate one sound at a slower tempo." }
        if extras>4 { return "Let the rests breathe. Extra taps count even when the correct notes land." }
        if abs(bias)>20 { return bias>0 ? "Your hits tend to arrive late. Slow down and let the click meet your finger.":"Your hits tend to arrive early. Leave more space before the next strike." }
        if median>45 { return "Keep the tempo here and make each repetition more even." }
        return "Keep the groove, remove a visual prompt, and see what you remember."
    }
}

struct PracticeCriteria {
    static func accepts(_ adjustedTime:Double)->Bool { adjustedTime >= -0.12 }
    static func passes(coverage:Double,extras:Int,median:Double,tolerance:Double)->Bool {
        coverage>=0.9 && extras<=1 && median<=tolerance
    }
}
