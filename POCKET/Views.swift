import SwiftUI
import UIKit

enum Ink {
    static let background=Color(red:0.055,green:0.061,blue:0.069)
    static let panel=Color(red:0.095,green:0.104,blue:0.113)
    static let accent=Color(red:0.98,green:0.72,blue:0.40)
    static let secondary=Color(red:0.59,green:0.62,blue:0.64)
    static let teal=Color(red:0.48,green:0.75,blue:0.74)
}
struct PrimaryButton:View {
    var title:String
    var icon:String="play.fill"
    var compact=false
    var action:()->Void
    var body:some View {
        Button(action:action) { Group {if compact {Image(systemName:icon).font(.system(size:18,weight:.semibold))} else {Label(title,systemImage:icon).font(.system(.headline,design:.rounded))}}.frame(maxWidth:.infinity).frame(minHeight:compact ? 44:52).foregroundStyle(Ink.background).background(Ink.accent,in:RoundedRectangle(cornerRadius:16)) }.accessibilityLabel(title).buttonStyle(.plain)
    }
}
struct RootView:View {
    @ObservedObject var s:Session
    var body:some View {
        GeometryReader { geo in
            VStack(spacing:0) {
                if geo.size.height<420 && s.tab==0 {
                    HStack { Text("POCKET").font(.system(size:13,weight:.black,design:.rounded));Spacer();Picker("Destination",selection:$s.tab) { Text("Learn").tag(0);Text("Practice").tag(1);Text("Play").tag(2) }.pickerStyle(.segmented).frame(maxWidth:300) }.padding(.horizontal,18).frame(height:40)
                }
                Group {
                    switch s.tab {
                    case 1:InstrumentScreen(s:s,free:false)
                    case 2:InstrumentScreen(s:s,free:true)
                    default:LearnView(s:s)
                    }
                }.frame(maxWidth:.infinity,maxHeight:.infinity)
                if geo.size.height>=420 && !s.running {
                    HStack(spacing:0) {
                        nav("Learn","square.stack.3d.up",0)
                        nav("Practice","metronome",1)
                        nav("Play","square.grid.2x2",2)
                    }.padding(.top,10).padding(.bottom,8).background(Ink.background)
                }
            }.background(Ink.background)
        }
        .tint(Ink.accent)
        .sheet(isPresented:$s.showSettings) { SettingsView(s:s) }
        .fullScreenCover(isPresented:$s.showLesson) { LessonView(s:s) }
        .alert("POCKET",isPresented:Binding(get:{!s.showLesson && s.error != nil},set:{if !$0 {s.error=nil}})) { Button("OK") {s.error=nil} } message: {Text(s.error ?? "")}
        .onChange(of:s.tab) { _,new in s.free=new==2 }
    }
    func nav(_ label:String,_ icon:String,_ index:Int)->some View {
        Button {s.stop();s.tab=index} label: {
            VStack(spacing:5) { Image(systemName:icon).font(.system(size:20,weight:.medium));Text(label).font(.system(size:11,weight:.semibold)) }.foregroundStyle(s.tab==index ? Ink.accent:Ink.secondary).frame(maxWidth:.infinity,minHeight:48)
        }.accessibilityAddTraits(s.tab==index ? .isSelected:[])
    }
}
struct LearnView:View {
    @ObservedObject var s:Session
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:26) {
                HStack {
                    HStack(spacing:7) { Image(systemName:"square.grid.2x2.fill").foregroundStyle(Ink.accent);Text("POCKET").tracking(3).font(.system(size:14,weight:.heavy,design:.rounded)) }
                    Spacer()
                    Button {s.showSettings=true} label:{ Image(systemName:"slider.horizontal.3").frame(width:44,height:44).foregroundStyle(.white) }.accessibilityLabel("Settings and MIDI controller")
                }
                VStack(alignment:.leading,spacing:9) {
                    Text("Find your\npocket.").font(.system(size:49,weight:.bold,design:.rounded)).tracking(-2).fixedSize(horizontal:false,vertical:true)
                    Text("Learn the rhythm. Make it yours.").font(.subheadline).foregroundStyle(Ink.secondary)
                }
                VStack(alignment:.leading,spacing:18) {
                    HStack { Text("YOUR NEXT SESSION").font(.system(size:10,weight:.bold)).tracking(2).foregroundStyle(Ink.accent);Spacer();Text("\(s.lessonID+1) / 24").font(.system(size:11,design:.monospaced)).foregroundStyle(Ink.secondary) }
                    HStack(alignment:.top,spacing:14) {
                        Image(systemName:"waveform.path").font(.system(size:27)).foregroundStyle(Ink.accent).frame(width:48,height:48).background(Ink.accent.opacity(0.09),in:RoundedRectangle(cornerRadius:13))
                        VStack(alignment:.leading,spacing:6) {Text(s.lesson.title).font(.system(.title3,design:.rounded,weight:.semibold));Text(s.lesson.purpose).font(.subheadline).foregroundStyle(Ink.secondary).fixedSize(horizontal:false,vertical:true)}
                    }
                    PrimaryButton(title:"Continue learning") {s.select(s.lesson)}
                    HStack {Label("Listen · Play · Remember",systemImage:"ear");Spacer();Text("\(s.lesson.bpm) BPM")}.font(.system(size:10,weight:.medium)).foregroundStyle(Ink.secondary)
                }.padding(20).background(Ink.panel,in:RoundedRectangle(cornerRadius:24))
                HStack(spacing:14) {
                    VStack(alignment:.leading,spacing:4) {Text("YOUR FOUNDATION").font(.system(size:10,weight:.bold)).tracking(2).foregroundStyle(Ink.secondary);Text("\(s.progressCount) skills made steady").font(.subheadline.weight(.medium))}
                    Spacer()
                    ZStack {Circle().stroke(.white.opacity(0.08),lineWidth:4);Circle().trim(from:0,to:Double(s.progressCount)/24).stroke(Ink.accent,style:StrokeStyle(lineWidth:4,lineCap:.round)).rotationEffect(.degrees(-90));Text("\(Int(Double(s.progressCount)/24*100))%").font(.system(size:10,design:.monospaced))}.frame(width:43,height:43)
                }.padding(.horizontal,3)
                ForEach(0..<6,id:\.self) { unit in
                    VStack(alignment:.leading,spacing:5) {
                        HStack {Text(String(format:"%02d",unit+1)).font(.system(size:11,design:.monospaced)).foregroundStyle(Ink.accent);Text(Lesson.units[unit]).font(.system(.headline,design:.rounded));Spacer()}.padding(.bottom,9)
                        ForEach(Lesson.all.filter{$0.unit==unit}) { lesson in
                            LessonRow(s:s,lesson:lesson)
                        }
                    }
                }
                Text("Practice that leaves the screen. Every skill includes listening, recall, and an idea to try in your own music.").font(.footnote).foregroundStyle(Ink.secondary).padding(.bottom,16)
            }.padding(.horizontal,24).padding(.top,12)
        }
    }
}
struct LessonRow:View {
    @ObservedObject var s:Session
    let lesson:Lesson
    var body:some View {
        Button {s.select(lesson)} label: {
            HStack(spacing:13) {
                ZStack {RoundedRectangle(cornerRadius:11).fill(Ink.panel);if s.state.progress[lesson.id]?.completed==true {Image(systemName:"checkmark").foregroundStyle(Ink.teal)} else {Text(String(format:"%02d",lesson.id+1)).font(.system(size:12,design:.monospaced)).foregroundStyle(Ink.secondary)}}.frame(width:42,height:42)
                VStack(alignment:.leading,spacing:4) {Text(lesson.title).font(.subheadline.weight(.medium)).foregroundStyle(.white);Text("\(lesson.bpm) BPM  ·  \(lesson.bars) bars\(s.state.progress[lesson.id]?.recalled==true ? "  ·  Recalled":"")").font(.system(size:10)).foregroundStyle(Ink.secondary)}
                Spacer();Image(systemName:"chevron.right").font(.system(size:11)).foregroundStyle(Ink.secondary)
            }.padding(.vertical,8).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}
struct LessonView:View {
    @ObservedObject var s:Session
    @State private var playing=false
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        ZStack {
            Ink.background.ignoresSafeArea()
            if playing { InstrumentScreen(s:s,free:false,onClose:{s.stop();playing=false}) }
            else {
                ScrollView {
                    VStack(alignment:.leading,spacing:24) {
                        HStack {Button {s.stop();dismiss()} label:{Image(systemName:"xmark").frame(width:44,height:44)};Spacer();Text("LESSON \(String(format:"%02d",s.lessonID+1))").font(.system(size:11,weight:.bold)).tracking(2).foregroundStyle(Ink.secondary);Spacer();Text("\(s.lesson.bpm)").font(.system(size:12,design:.monospaced)).frame(width:44)}
                        Text(s.lesson.unitName.uppercased()).font(.system(size:11,weight:.bold)).tracking(2).foregroundStyle(Ink.accent)
                        Text(s.lesson.title).font(.system(size:38,weight:.bold,design:.rounded)).tracking(-1)
                        Text(s.lesson.purpose).font(.title3).foregroundStyle(Ink.secondary)
                        teaching("01",title:"What to play",text:s.lesson.instruction)
                        VStack(alignment:.leading,spacing:9) {Text("COUNT IT OUT").font(.system(size:10,weight:.bold)).tracking(2).foregroundStyle(Ink.accent);Text(s.lesson.count).font(.system(.body,design:.monospaced)).fixedSize(horizontal:false,vertical:true)}.frame(maxWidth:.infinity,alignment:.leading).padding(20).background(Ink.panel,in:RoundedRectangle(cornerRadius:18))
                        teaching("02",title:"What to listen for",text:s.lesson.mistake)
                        teaching("03",title:"Take it into your music",text:s.lesson.transfer)
                        if s.lessonID==12 {Text("Touch mode uses a separate ghost-note sound. True strike-velocity assessment is available with a MIDI pad controller.").font(.footnote).foregroundStyle(Ink.teal)}
                        PrimaryButton(title:"Hear it, then play",icon:"ear") {s.free=false;playing=true;s.start(demo:true)}
                        Button {s.free=false;playing=true} label:{Text("Go straight to the pads").font(.subheadline.weight(.semibold)).frame(maxWidth:.infinity,minHeight:44)}
                    }.padding(24)
                }
            }
        }.tint(Ink.accent).onDisappear{s.stop()}
        .sheet(isPresented:$s.showSettings) {SettingsView(s:s)}
    }
    func teaching(_ number:String,title:String,text:String)->some View {
        HStack(alignment:.top,spacing:14) {Text(number).font(.system(size:11,design:.monospaced)).foregroundStyle(Ink.accent).padding(.top,4);VStack(alignment:.leading,spacing:7) {Text(title).font(.headline);Text(text).font(.body).foregroundStyle(Ink.secondary).fixedSize(horizontal:false,vertical:true)}}
    }
}
