import SwiftUI
import AVFoundation

enum TrainingMode:String,CaseIterable,Identifiable {
    case guided="Guided",memory="Memory",echo="Echo",wait="Wait",silent="Silent bars"
    var id:String { rawValue }
    var detail:String {
        switch self {
        case .guided:return "Follow the rhythm, then reduce the guide."
        case .memory:return "Play without upcoming notes or pad prompts."
        case .echo:return "Listen first. Then answer with the phrase from memory."
        case .wait:return "Untimed: the phrase waits for the correct sound."
        case .silent:return "The click disappears every other bar. Hold the pulse."
        }
    }
}
struct TimedPad { var time:Double;var pad:Int;var velocity:Float;var role:Int { DrumPad.all[pad].role };var hand:String?=nil }
struct ShareFile:Identifiable { let id=UUID();let url:URL }

final class Session:ObservableObject {
    @Published var tab=0
    @Published var lessonID=0
    @Published var showLesson=false
    @Published var showSettings=false
    @Published var mode:TrainingMode = .guided
    @Published var bpm=65
    @Published var bars=4
    @Published var focusRole = -1
    @Published var guide=2
    @Published var fullBank=false
    @Published var repeatPractice=false
    @Published var metronome=true
    @Published var demoVolume:Float=0.7
    @Published var positional=false
    @Published var leftHand=false
    @Published var kit=UserDefaults.standard.integer(forKey:"kit") { didSet { UserDefaults.standard.set(kit,forKey:"kit") } }
    @Published var running=false
    @Published var listening=false
    @Published var replaying=false
    @Published var free=false
    @Published var beat = -4.0
    @Published var lastPad = -1
    @Published var lastHitTime=0.0
    @Published var feedback="Ready when you are"
    @Published var timing:Double?
    @Published var result:PracticeResult?
    @Published var state=SavedState()
    @Published var error:String?
    @Published var midiStatus="Connect a USB MIDI controller"
    @Published var midiConnected=false
    @Published var learnPad:Int?
    @Published var share:ShareFile?
    @Published var exporting=false
    @Published var calibrating=false
    @Published var calibrationCount=0
    @Published var audioDescription="Starting audio…"
    @Published var audioReady=false
    var noteMap:[Int:Int] = [36:0,35:1,38:5,40:3,42:7,44:2,46:6,39:10,37:11,49:12,51:13,50:14,45:15,75:8,82:9]
    let audio=AudioEngine()
    private let midi=MIDIInput()
    private let saveQueue=DispatchQueue(label:"pocket.ordered-saves",qos:.utility)
    private var clock:Timer?
    private var observers=[NSObjectProtocol]()
    private var origin=0.0
    private var targets=[TimedPad]()
    private var input=[PlayedHit]()
    private var soundQueue=[TimedPad]()
    private var soundIndex=0
    private var clickIndex = -4
    private var totalBeats=16.0
    private var matched=Set<Int>()
    private var waitIndex=0
    private var calibrationOrigin=0.0
    private var calibrationErrors=[Int:Double]()
    private var calibrationClick=0
    private var echoAnswer=false
    private var replayTake:Take?
    var lesson:Lesson { Lesson.all[max(0,min(23,lessonID))] }
    var progressCount:Int { state.progress.values.filter(\.completed).count }
    var offsetMs:Double { (UserDefaults.standard.dictionary(forKey:"offsets")?[audio.routeKey] as? Double) ?? 0 }
    var activePads:[Int] {
        if fullBank || free { return (0..<16).map{$0} }
        let p=lesson.pads
        if p.count<=4 { return Array(Set(p+[0,5,7,6])).sorted() }
        return Array(Set(p+[0,5,7,6])).sorted()
    }
    var upcoming:Set<Int> {
        guard running,!free,!replaying,!listening else { return [] }
        if mode == .wait { return waitIndex<targets.count ? [targets[waitIndex].pad]:[] }
        guard mode == .guided,guide==2 else { return [] }
        let elapsed=AudioEngine.now-origin
        return Set(targets.filter{$0.time-elapsed>=0 && $0.time-elapsed<0.20}.map(\.pad))
    }
    init() {
        do { state=try StateStore.load();self.error=StateStore.recoveryNotice } catch { self.error="Your previous save could not be read. A recovery copy was kept. New practice is available." }
        if let map=UserDefaults.standard.dictionary(forKey:"noteMap") { for (key,value) in map { if let note=Int(key),let pad=value as? Int,(0..<16).contains(pad) { noteMap[note]=pad } } }
        lessonID=(0..<24).first { state.progress[$0]?.completed != true } ?? 23
        bpm=lesson.bpm;bars=lesson.bars
        prepareAudio()
        midi.onNote={ [weak self] note,velocity,time in
            guard let self else { return }
            if let pad=self.learnPad {
                self.noteMap[note]=pad;self.learnPad=nil
                UserDefaults.standard.set(Dictionary(uniqueKeysWithValues:self.noteMap.map{(String($0.key),$0.value)}),forKey:"noteMap")
                self.feedback="MIDI note \(note) → \(DrumPad.all[pad].name)"
            }
            if let pad=self.noteMap[note] { self.strike(pad,velocity:velocity,timestamp:time,midi:true,sourceNote:note) }
        }
        midi.onStatus={ [weak self] status,connected in
            guard let self else { return }
            let wasConnected=self.midiConnected
            self.midiStatus=status;self.midiConnected=connected
            if wasConnected && !connected && self.running { self.stop();self.feedback="Controller disconnected. Reconnect and restart with a count-in." }
        }
        midi.onSourceRemoved={ [weak self] in
            guard let self else {return}
            if self.running { self.stop();self.feedback="A MIDI input disconnected. Restart with a count-in." }
        }
        midi.start()
        observers.append(NotificationCenter.default.addObserver(forName:AVAudioSession.interruptionNotification,object:nil,queue:.main) { [weak self] _ in
            self?.stop();self?.audioReady=false;self?.feedback="Audio interrupted. Tap Retry audio to resume."
        })
        observers.append(NotificationCenter.default.addObserver(forName:AVAudioSession.routeChangeNotification,object:nil,queue:.main) { [weak self] _ in
            self?.stop();self?.prepareAudio();self?.feedback="Audio route changed. Check timing alignment before assessed practice."
        })
        clock=Timer.scheduledTimer(withTimeInterval:1.0/60,repeats:true) { [weak self] _ in self?.tick() }
        if let index=ProcessInfo.processInfo.arguments.firstIndex(of:"-preview"),ProcessInfo.processInfo.arguments.count>index+1 {
            switch ProcessInfo.processInfo.arguments[index+1] {
            case "practice":tab=1
            case "play":tab=2;free=true
            case "lesson":showLesson=true
            default:break
            }
        }
    }
    var upcomingHands:[Int:String] {
        guard mode == .guided,guide==2,running else {return [:]}
        let elapsed=AudioEngine.now-origin
        var labels=[Int:String]()
        for note in targets where note.time>=elapsed && note.time<elapsed+0.2 {
            if let hand=note.hand { labels[note.pad]=leftHand ? (hand=="L" ? "R":"L"):hand }
        }
        return labels
    }
    private func matchingWindow(_ index:Int)->Double {
        let target=targets[index]
        return targets.indices.filter{$0 != index && targets[$0].role==target.role && abs(targets[$0].time-target.time)>0.000001}.reduce(0.12) {min($0,abs(targets[$1].time-target.time)*0.49)}
    }
    func prepareAudio() {
        do { try audio.prepare();audioReady=true;audioDescription="\(audio.route) · \(Int(audio.sampleRate)) Hz · \(String(format:"%.1f",audio.bufferMs)) ms buffer" }
        catch { audioReady=false;audioDescription="Audio needs attention";self.error="Could not start the instrument: \(error.localizedDescription). Retry audio in Settings." }
    }
    func select(_ lesson:Lesson) { stop();lessonID=lesson.id;bpm=lesson.bpm;bars=lesson.bars;focusRole = -1;result=nil;free=false;mode = .guided;showLesson=true;feedback="Listen first, then try it slowly." }
    func start(demo:Bool=false,answer:Bool=false) {
        guard audioReady else { error="Open Settings and retry audio before playing.";return }
        stop(save:false)
        result=nil;timing=nil;input=[];matched=[];waitIndex=0;replayTake=nil
        echoAnswer=answer;listening=demo || (mode == .echo && !answer && !free)
        running=true;replaying=false
        totalBeats=free ? Double(bpm)*2:Double(bars*4)
        let spb=60/Double(bpm)
        origin=AudioEngine.now+(mode == .wait && !free && !listening ? 0.05:4*spb)
        beat = -4
        targets=[]
        if !free {
            let baseLength=Double(lesson.bars*4)
            for b in stride(from:0.0,to:totalBeats,by:baseLength) {
                for note in lesson.notes where b+note.beat<totalBeats {
                    if focusRole>=0 && note.role != focusRole { continue }
                    let feel=note.timeOffset
                    targets.append(TimedPad(time:(b+note.beat)*spb+feel,pad:note.pad,velocity:note.velocity,hand:note.hand))
                }
            }
        }
        soundQueue=listening ? targets:[];soundIndex=0;clickIndex = -4
        feedback=listening ? "Listen to the complete phrase":(free ? "Your take starts after four clicks":mode.detail)
        tick()
    }
    func strike(_ pad:Int,velocity:Float=0.8,timestamp:Double?=nil,midi:Bool=false,sourceNote:Int?=nil) {
        guard (0..<16).contains(pad),audioReady else { return }
        if !audio.play(pad,velocity:velocity,kit:kit) { error="The audio event queue is full. Stop and retry audio.";stop();return }
        let now=timestamp ?? AudioEngine.now
        lastPad=pad;lastHitTime=AudioEngine.now
        if calibrating {
            let relative=(now-calibrationOrigin)/(60.0/80)
            let index=relative.rounded()
            if index>=1 && index<9 && abs(relative-index)<0.3 {
                let error=(now-(calibrationOrigin+index*60/80))*1000
                if calibrationErrors[Int(index)]==nil { calibrationErrors[Int(index)]=error;calibrationCount=calibrationErrors.count }
            }
            return
        }
        guard running,!listening,!replaying else { return }
        let rawElapsed=now-origin
        let elapsed=rawElapsed-offsetMs/1000
        guard PracticeCriteria.accepts(elapsed) else { feedback="Count in: wait for 1";return }
        if mode == .wait && !free {
            if waitIndex<targets.count,DrumPad.all[pad].role==targets[waitIndex].role {
                beat=targets[waitIndex].time*Double(bpm)/60;waitIndex+=1;feedback="Good. Find the next sound."
            } else { feedback="Try the highlighted sound.";return }
        }
        input.append(PlayedHit(time:rawElapsed,pad:pad,velocity:velocity,midi:midi,sourceNote:sourceNote,assessmentTime:elapsed))
        if !free && mode != .wait {
            let role=DrumPad.all[pad].role
            let best=targets.indices.filter { !matched.contains($0) && targets[$0].role==role && abs(targets[$0].time-elapsed)<=matchingWindow($0) }.min { abs(targets[$0].time-elapsed)<abs(targets[$1].time-elapsed) }
            if let best {
                matched.insert(best);let difference=(elapsed-targets[best].time)*1000;timing=difference
                feedback=abs(difference)<20 ? "Centered":(difference<0 ? "Early":"Late")
            } else { timing=nil;feedback="Extra strike — keep the space" }
        }
        if mode == .wait && !free && waitIndex>=targets.count { finish() }
    }
    private func tick() {
        let now=AudioEngine.now
        if lastPad>=0 && now-lastHitTime>0.11 { lastPad = -1 }
        if calibrating {
            while calibrationClick<10 && calibrationOrigin+Double(calibrationClick)*60/80<now+0.15 {
                audio.play(calibrationClick==0 ? 17:16,velocity:0.65,at:calibrationOrigin+Double(calibrationClick)*60/80);calibrationClick+=1
            }
            if now>calibrationOrigin+10*60/80 {
                calibrating=false;audio.cancel()
                if calibrationErrors.count>=4 {
                    let sorted=calibrationErrors.values.sorted();setOffset(sorted[sorted.count/2]);feedback="Alignment saved from \(sorted.count) taps. This includes your own tap timing."
                } else { feedback="Not enough aligned taps. Try calibration again." }
            }
            return
        }
        guard running else { return }
        if mode == .wait && !free && !listening && !replaying { return }
        beat=(now-origin)*Double(bpm)/60
        while soundIndex<soundQueue.count && origin+soundQueue[soundIndex].time<now+0.15 {
            let event=soundQueue[soundIndex]
            audio.play(event.pad,velocity:event.velocity*(replaying ? 1:demoVolume),at:origin+event.time,kit:kit);soundIndex+=1
        }
        let shouldClick=metronome && !replaying
        while clickIndex<Int(totalBeats) && origin+Double(clickIndex)*60/Double(bpm)<now+0.15 {
            let silent=mode == .silent && clickIndex>=0 && (clickIndex/4)%2==1
            if clickIndex<0 || (shouldClick && !silent) { audio.play(clickIndex%4==0 ? 17:16,velocity:0.4,at:origin+Double(clickIndex)*60/Double(bpm)) }
            clickIndex+=1
        }
        if beat>=totalBeats+0.15*Double(bpm)/60 { finish() }
    }
    private func finish() {
        let wasListening=listening,wasReplay=replaying
        running=false;listening=false;replaying=false;audio.cancel()
        if wasReplay { feedback="Playback finished";return }
        if wasListening {
            feedback="Now play what you heard."
            if mode == .echo && !echoAnswer { start(answer:true) }
            return
        }
        if free { saveTake();feedback="Take saved. Listen back or export it below.";return }
        let t=targets.map { PDEvent(time:$0.time,role:Int32($0.role),velocity:$0.velocity) }
        let h=input.map { PDEvent(time:$0.assessmentTime ?? $0.time,role:Int32(DrumPad.all[$0.pad].role),velocity:$0.velocity) }
        var score=PDResult()
        t.withUnsafeBufferPointer { ts in h.withUnsafeBufferPointer { hs in pd_score(ts.baseAddress,Int32(ts.count),hs.baseAddress,Int32(hs.count),0.12,&score) } }
        let assessed=mode != .wait
        let dynamic = !input.isEmpty && input.allSatisfy(\.midi)
        let coverage=targets.isEmpty ? 0:Double(score.hits)/Double(targets.count)
        let passed=assessed && PracticeCriteria.passes(coverage:coverage,extras:Int(score.extras),median:score.medianErrorMs,tolerance:lesson.tolerance) && (lessonID != 12 || !dynamic || score.velocityError<=0.18)
        result=PracticeResult(hits:Int(score.hits),extras:Int(score.extras),misses:Int(score.misses),bias:score.biasMs,median:score.medianErrorMs,spread:score.spreadMs,velocityError:score.velocityError,total:targets.count,passed:passed,assessed:assessed,velocityAssessed:dynamic)
        saveTake()
        var record=state.progress[lessonID] ?? ProgressRecord()
        record.attempts+=1;record.bestCoverage=max(record.bestCoverage,coverage)
        if assessed { record.consecutive=(passed && bars>=4 && focusRole<0) ? record.consecutive+1:0 }
        if passed { record.bestBPM=max(record.bestBPM,bpm);if mode == .memory || mode == .echo { record.recalled=true } }
        if record.consecutive>=3 && bars>=4 && focusRole<0 { record.completed=true }
        state.progress[lessonID]=record;persist()
        feedback=passed ? "Solid phrase. \(min(3,record.consecutive))/3 toward a stable groove.":result?.suggestion ?? "Try again slowly."
        if repeatPractice { start(answer:mode == .echo) }
    }
    func stop(save:Bool=true) {
        if running && !listening && !replaying && save { saveTake() }
        running=false;listening=false;replaying=false;calibrating=false;audio.cancel();beat = -4
    }
    private func saveTake() {
        guard !input.isEmpty else { return }
        let duration=min(120,max(input.last?.time ?? 0,min(max(0,AudioEngine.now-origin),totalBeats*60/Double(bpm))))
        let take=Take(title:free ? "Free play":lesson.title,bpm:bpm,kit:kit,duration:duration,hits:input,padNotes:(0..<16).map {pad in noteMap.filter{$0.value==pad}.keys.sorted().first ?? TakeExporter.notes[pad]})
        state.takes.insert(take,at:0);state.takes=Array(state.takes.prefix(50));input=[];persist()
    }
    func persist() {
        let snapshot=state
        saveQueue.async { [weak self] in
            do { try StateStore.save(snapshot) }
            catch { DispatchQueue.main.async { self?.error="Could not save this practice: \(error.localizedDescription). Keep the app open and try again." } }
        }
    }
    func replay(_ take:Take) {
        stop();free=true;tab=2;result=nil;running=true;replaying=true;listening=false;replayTake=take
        origin=AudioEngine.now+0.2;bpm=take.bpm;kit=take.kit;totalBeats=(take.duration+1.2)*Double(bpm)/60
        soundQueue=take.hits.map { TimedPad(time:$0.time,pad:$0.pad,velocity:$0.velocity) }.sorted{$0.time<$1.time};soundIndex=0;clickIndex=Int(totalBeats);feedback="Playing your unquantized take"
    }
    func export(_ take:Take,wave:Bool) {
        guard !exporting else { return };exporting=true
        Task {
            do {
                let url=try await Task.detached(priority:.userInitiated) { try TakeExporter.file(take,wave:wave) }.value
                await MainActor.run { self.exporting=false;self.share=ShareFile(url:url) }
            } catch { await MainActor.run { self.exporting=false;self.error="Export failed. Your take is still saved. \(error.localizedDescription)" } }
        }
    }
    func beginCalibration() {
        stop();guard audioReady else { return }
        calibrating=true;calibrationOrigin=AudioEngine.now+0.5;calibrationClick=0;calibrationErrors=[:];calibrationCount=0
        feedback="Listen to one click, then tap the kick on each click."
    }
    func setOffset(_ value:Double) {
        var offsets=UserDefaults.standard.dictionary(forKey:"offsets") ?? [:]
        offsets[audio.routeKey]=max(-200,min(200,value));UserDefaults.standard.set(offsets,forKey:"offsets");objectWillChange.send()
    }
    deinit { clock?.invalidate();observers.forEach(NotificationCenter.default.removeObserver) }
}
