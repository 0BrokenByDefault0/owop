import SwiftUI

struct InstrumentScreen:View {
    @ObservedObject var s:Session
    var free:Bool
    var onClose:(()->Void)?=nil
    @State private var setup=false
    @State private var course=false
    @State private var takes=false
    @State private var review=false
    var body:some View {
        GeometryReader { geo in
            let compact=geo.size.height<400
            VStack(spacing:compact ? 7:14) {
                HStack(spacing:12) {
                    if let onClose {Button(action:onClose) {Image(systemName:"chevron.left").frame(width:44,height:44)}.accessibilityLabel("Back to lesson")}
                    VStack(alignment:.leading,spacing:3) {
                        Text(free ? "PLAY":"PRACTICE").font(.system(size:10,weight:.bold)).tracking(2).foregroundStyle(Ink.accent)
                        if !compact { Text(free ? "Make something yours.":s.lesson.title).font(.system(.title3,design:.rounded,weight:.semibold)).lineLimit(1).minimumScaleFactor(0.8) }
                    }
                    Spacer(minLength:0)
                    Button {s.stop();setup=true} label: {Text("\(s.bpm)").font(.system(size:22,weight:.semibold,design:.rounded))+Text(" BPM").font(.system(size:9,weight:.bold))}.frame(minWidth:70,minHeight:44).accessibilityLabel("Tempo \(s.bpm) beats per minute. Practice setup.")
                    Button {s.stop();s.showSettings=true} label:{Image(systemName:"slider.horizontal.3").frame(width:44,height:44)}.accessibilityLabel("Audio and MIDI settings")
                }.foregroundStyle(.white).frame(height:compact ? 36:48)
                if !compact {
                    HStack {
                        if free {Button {s.stop();takes=true} label:{Label("Saved takes · \(s.state.takes.count)",systemImage:"waveform")}}
                        else {Button {s.stop();course=true} label:{Label("Change lesson",systemImage:"square.stack")}}
                        Spacer()
                        Button {s.fullBank.toggle()} label:{Label(s.fullBank ? "Focus pads":"16 pads",systemImage:s.fullBank ? "square.grid.2x2":"square.grid.4x4")}.disabled(s.running)
                    }.font(.system(size:11,weight:.medium)).foregroundStyle(Ink.secondary).frame(minHeight:28)
                    if !free && s.mode != .memory && s.mode != .echo && s.guide>0 {RhythmStrip(s:s).frame(height:57)}
                    else {PulseRow(s:s).frame(height:42)}
                    HStack {
                        Text(s.running && s.beat<0 ? "COUNT IN · \(max(1,Int(ceil(-s.beat))))":s.feedback).font(.system(size:12,weight:.medium)).foregroundStyle(s.timing == nil ? Ink.secondary:Ink.accent).lineLimit(2).frame(minHeight:32,alignment:.leading)
                        Spacer(minLength:4)
                        if let timing=s.timing {Text(String(format:"%+.0f ms",timing)).font(.system(size:11,design:.monospaced)).foregroundStyle(Ink.accent)}
                    }
                }
                PadSurface(session:s,full:free).frame(maxWidth:.infinity,maxHeight:.infinity).layoutPriority(1)
                if !compact {
                    if !s.audioReady {Button("Retry audio") {s.prepareAudio()}.frame(minHeight:44)}
                    else if let result=s.result,!free {Button {review=true} label:{HStack {Image(systemName:result.passed ? "checkmark.circle":"chart.bar.xaxis");Text(result.assessed ? "\(Int(result.coverage*100))% notes · \(Int(result.median)) ms median":"Untimed phrase complete");Spacer();Text("Review");Image(systemName:"arrow.up.right")}.font(.system(size:11,weight:.medium)).padding(12).foregroundStyle(result.passed ? Ink.teal:Ink.accent).background(Ink.panel,in:RoundedRectangle(cornerRadius:12))}}
                    else {HStack {Text(free ? "Live pads · Original \(s.kit==0 ? "Dry":"Warm") kit":"\(s.mode.rawValue) · \(s.bars) bars · \(s.fullBank ? "Full bank":"Focus view")");Spacer();Circle().fill(s.audioReady ? Ink.teal:Color.red).frame(width:5,height:5);Text(s.audioReady ? "AUDIO READY":"AUDIO OFF")}.font(.system(size:9,weight:.medium)).foregroundStyle(Ink.secondary)}
                }
                HStack(spacing:10) {
                    if !free {Button {if s.running {s.stop()} else {s.free=false;s.start(demo:true)}} label:{Image(systemName:"ear").font(.system(size:20)).frame(width:52,height:compact ? 44:52).background(Ink.panel,in:RoundedRectangle(cornerRadius:14))}.accessibilityLabel("Listen to the lesson")}
                    PrimaryButton(title:s.running ? (s.listening ? "Stop listening":"Stop"):(free ? "Record a take":"Start practice"),icon:s.running ? "stop.fill":(free ? "record.circle":"play.fill")) {
                        if s.running {s.stop()} else {s.free=free;s.start()}
                    }
                    Button {s.stop();setup=true} label:{Image(systemName:"metronome").font(.system(size:20)).frame(width:52,height:compact ? 44:52).background(Ink.panel,in:RoundedRectangle(cornerRadius:14))}.accessibilityLabel("Practice setup")
                }.foregroundStyle(Ink.accent)
            }.padding(.horizontal,compact ? 14:22).padding(.top,compact ? 2:14).padding(.bottom,compact ? 2:12)
        }.background(Ink.background)
        .onAppear {s.free=free}
        .sheet(isPresented:$setup) {PracticeSetup(s:s,free:free)}
        .sheet(isPresented:$course) {NavigationStack {List(Lesson.all) { lesson in Button {s.lessonID=lesson.id;s.bpm=lesson.bpm;s.bars=lesson.bars;s.focusRole = -1;s.result=nil;course=false} label:{VStack(alignment:.leading,spacing:5) {Text(lesson.title);Text(lesson.purpose).font(.caption).foregroundStyle(.secondary)}} }.navigationTitle("Choose a skill").toolbar {ToolbarItem(placement:.confirmationAction) {Button("Done"){course=false}}}}}
        .sheet(isPresented:$takes) {TakesView(s:s)}
        .sheet(isPresented:$review) {ResultsView(s:s)}
    }
}
struct PulseRow:View {
    @ObservedObject var s:Session
    var body:some View {
        HStack(spacing:14) {
            ForEach(0..<4,id:\.self) { i in ZStack {Circle().fill(s.running && s.beat>=0 && Int(s.beat)%4==i ? Ink.accent:Ink.panel);Text("\(i+1)").font(.system(size:13,weight:.semibold,design:.rounded)).foregroundStyle(s.running && s.beat>=0 && Int(s.beat)%4==i ? Ink.background:Ink.secondary)}.frame(width:34,height:34).accessibilityLabel("Beat \(i+1)")}
            Spacer();Text(s.mode == .memory || s.mode == .echo ? "TRUST YOUR PULSE":"MAKE ROOM\nFOR THE GROOVE").font(.system(size:9,weight:.bold)).tracking(1).foregroundStyle(Ink.secondary)
        }
    }
}
struct RhythmStrip:View {
    @ObservedObject var s:Session
    var body:some View {
        HStack(spacing:8) {
            VStack(alignment:.leading,spacing:3) {Text("HAT");Text("SNARE");Text("KICK")}.font(.system(size:8,weight:.bold)).foregroundStyle(Ink.secondary).frame(width:35,alignment:.leading)
            Canvas { context,size in
                let bar=max(0,Int(s.beat/4))%s.lesson.bars
                for i in 0..<16 {
                    let x=CGFloat(i)/16*size.width
                    var path=Path();path.move(to:CGPoint(x:x,y:0));path.addLine(to:CGPoint(x:x,y:size.height))
                    context.stroke(path,with:.color(.white.opacity(i%4==0 ? 0.15:0.04)),lineWidth:1)
                }
                for note in s.lesson.notes where Int(note.beat/4)==bar && (s.focusRole<0 || note.role==s.focusRole) {
                    let x=CGFloat(note.beat-Double(bar*4))/4*size.width
                    let row=note.role==0 ? 2:(note.role==1 ? 1:0)
                    let color=note.role==0 ? Ink.accent:(note.role==1 ? Color(red:0.94,green:0.48,blue:0.43):Ink.teal)
                    let rect=CGRect(x:x+2,y:CGFloat(row)*16+3,width:5,height:8)
                    context.fill(Path(roundedRect:rect,cornerRadius:2),with:.color(color.opacity(0.9)))
                }
                if s.running && s.beat>=0 {
                    let x=CGFloat(s.beat.truncatingRemainder(dividingBy:4))/4*size.width
                    var line=Path();line.move(to:CGPoint(x:x,y:0));line.addLine(to:CGPoint(x:x,y:size.height));context.stroke(line,with:.color(.white),lineWidth:1.5)
                }
            }
        }.padding(8).background(Ink.panel,in:RoundedRectangle(cornerRadius:12)).accessibilityElement(children:.ignore).accessibilityLabel("Rhythm guide. \(s.lesson.count)")
    }
}
struct PracticeSetup:View {
    @ObservedObject var s:Session
    var free:Bool
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        NavigationStack {
            Form {
                Section("Tempo") {
                    HStack {Text("\(s.bpm) BPM").monospacedDigit();Spacer();Button("−5"){s.bpm=max(30,s.bpm-5)}.buttonStyle(.borderless);Button("+5"){s.bpm=min(180,s.bpm+5)}.buttonStyle(.borderless)}
                    Slider(value:Binding(get:{Double(s.bpm)},set:{s.bpm=Int($0)}),in:30...180,step:1).accessibilityLabel("Tempo")
                    Toggle("Metronome",isOn:$s.metronome)
                }
                if !free {
                    Section("Learn by doing") {
                        Picker("Practice mode",selection:$s.mode) {ForEach(TrainingMode.allCases) {Text($0.rawValue).tag($0)}}
                        Text(s.mode.detail).font(.footnote).foregroundStyle(.secondary)
                        Picker("Phrase length",selection:$s.bars) {Text("1 bar").tag(1);Text("2 bars").tag(2);Text("4 bars").tag(4);Text("8 bars").tag(8)}
                        Picker("Isolate a part",selection:$s.focusRole) {Text("All sounds").tag(-1);ForEach(Array(Set(s.lesson.notes.map(\.role))).sorted(),id:\.self) {role in Text(DrumPad.all[DrumPad.primary(role)].name).tag(role)}}
                        Picker("Visual guide",selection:$s.guide) {Text("Rhythm + pads").tag(2);Text("Rhythm only").tag(1);Text("No prompts").tag(0)}
                        Toggle("Repeat with a count-in",isOn:$s.repeatPractice)
                        Text("A stable skill takes three full phrases with at least 90% of notes, few extra strikes, and median timing within \(Int(s.lesson.tolerance)) ms. All-sound phrases of four bars or more count toward completion.").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Section("Instrument") {
                    Picker("Kit",selection:$s.kit) {Text("Original Dry").tag(0);Text("Original Warm").tag(1)}
                    Toggle("Full 16-pad bank",isOn:$s.fullBank)
                    Text("Focus view enlarges the lesson's sounds. Each pad keeps its number and sound in the full bank.").font(.footnote).foregroundStyle(.secondary)
                    Text("Demonstration level").font(.subheadline)
                    Slider(value:$s.demoVolume,in:0.1...1).accessibilityLabel("Demonstration level")
                }
            }.navigationTitle("Your practice").toolbar {ToolbarItem(placement:.confirmationAction) {Button("Done") {dismiss()}}}
        }.tint(Ink.accent)
    }
}
struct ResultsView:View {
    @ObservedObject var s:Session
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        NavigationStack {
            ScrollView {
                if let r=s.result {
                    VStack(alignment:.leading,spacing:23) {
                        Image(systemName:r.passed ? "checkmark.circle":"waveform.path").font(.system(size:39)).foregroundStyle(Ink.accent)
                        Text(r.assessed ? (r.passed ? "That's a solid phrase.":"Here's your next step."):"Movement before speed.").font(.system(size:29,weight:.bold,design:.rounded))
                        Text(r.suggestion).foregroundStyle(Ink.secondary)
                        if r.assessed {
                            HStack {metric("NOTES",value:"\(Int(r.coverage*100))%");metric("MEDIAN ERROR",value:"\(Int(r.median)) ms")}
                            HStack {metric("EXTRA HITS",value:"\(r.extras)");metric("MISSED",value:"\(r.misses)")}
                            HStack {metric("TIMING BIAS",value:String(format:"%+.0f ms",r.bias));metric("VARIATION",value:"\(Int(r.spread)) ms")}
                            Text("Bias shows a consistent lead or delay. Median error shows typical distance from the target. Variation shows how much timing changes between hits.").font(.footnote).foregroundStyle(Ink.secondary)
                            if s.lessonID==12 {Text(r.velocityAssessed ? "MIDI dynamics error: \(Int(r.velocityError*100))%. Lower is closer to the demonstrated accents.":"Timing was assessed. True strike dynamics need a velocity-sensitive MIDI controller.").font(.footnote).foregroundStyle(Ink.teal)}
                        }
                        if let p=s.state.progress[s.lessonID] {Text("\(min(3,p.consecutive))/3 steady phrases · \(p.recalled ? "Recall demonstrated":"Memory practice available")").font(.subheadline).foregroundStyle(Ink.accent)}
                        PrimaryButton(title:"Play it again") {dismiss();s.start(answer:s.mode == .echo)}
                        Button {s.mode = .memory;dismiss();s.start()} label:{Text("Try it from memory").frame(maxWidth:.infinity,minHeight:44)}
                        HStack {Button("Slow down 5 BPM") {s.bpm=max(30,s.bpm-5);dismiss()};Spacer();Button("Try +3 BPM") {s.bpm=min(180,s.bpm+3);dismiss()}}.font(.footnote)
                        Text("In your own music").font(.headline)
                        Text(s.lesson.transfer).foregroundStyle(Ink.secondary)
                    }.padding(24)
                }
            }.background(Ink.background).navigationTitle("Your phrase").navigationBarTitleDisplayMode(.inline).toolbar {ToolbarItem(placement:.confirmationAction){Button("Done"){dismiss()}}}
        }.tint(Ink.accent)
    }
    func metric(_ title:String,value:String)->some View {VStack(alignment:.leading,spacing:8) {Text(title).font(.system(size:9,weight:.bold)).tracking(1).foregroundStyle(Ink.secondary);Text(value).font(.system(size:27,weight:.medium,design:.rounded))}.frame(maxWidth:.infinity,alignment:.leading).padding(15).background(Ink.panel,in:RoundedRectangle(cornerRadius:15))}
}
struct TakesView:View {
    @ObservedObject var s:Session
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        NavigationStack {
            List {
                if s.state.takes.isEmpty {ContentUnavailableView("Your first take is waiting",systemImage:"waveform",description:Text("Record in Play or finish a lesson phrase. Your latest 50 performances stay here."))}
                ForEach(s.state.takes) {take in
                    VStack(alignment:.leading,spacing:10) {
                        HStack {VStack(alignment:.leading,spacing:4) {Text(take.title).font(.headline);Text("\(take.bpm) BPM · \(take.hits.count) hits · \(Int(take.duration)) sec").font(.caption).foregroundStyle(.secondary)};Spacer();Button {dismiss();s.replay(take)} label:{Image(systemName:"play.fill").frame(width:44,height:44)}.buttonStyle(.borderless).accessibilityLabel("Replay \(take.title)")}
                        HStack {Text(take.date,style:.date).font(.caption2).foregroundStyle(.secondary);Spacer();Button("MIDI") {dismiss();s.export(take,wave:false)}.buttonStyle(.borderless);Button("WAV") {dismiss();s.export(take,wave:true)}.buttonStyle(.borderless)}
                    }.padding(.vertical,5)
                }.onDelete {indices in s.state.takes.remove(atOffsets:indices);s.persist()}
                Text("Performances keep your original timing. MIDI uses the drum map; WAV renders your chosen original kit. The latest 50 takes are retained.").font(.footnote).foregroundStyle(.secondary)
            }.navigationTitle("Your takes").toolbar {ToolbarItem(placement:.confirmationAction){Button("Done"){dismiss()}}}
        }.tint(Ink.accent)
    }
}
struct ActivitySheet:UIViewControllerRepresentable {
    let url:URL
    func makeUIViewController(context:Context)->UIActivityViewController {UIActivityViewController(activityItems:[url],applicationActivities:nil)}
    func updateUIViewController(_ controller:UIActivityViewController,context:Context) {}
}
