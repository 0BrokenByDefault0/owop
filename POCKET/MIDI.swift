import Foundation
import CoreMIDI
import AVFoundation

struct MIDIStreamParser {
    private var status:UInt8=0
    private var bytes=[UInt8]()
    private var sysex=false
    mutating func feed(_ data:[UInt8])->[(Int,Int)] {
        var notes=[(Int,Int)]()
        for byte in data {
            if byte>=0xf8 { continue }
            if byte==0xf0 { sysex=true;status=0;bytes=[];continue }
            if byte==0xf7 { sysex=false;continue }
            if sysex { continue }
            if byte&0x80 != 0 { status=byte;bytes=[];continue }
            guard status>=0x80 && status<0xf0 else { continue }
            bytes.append(byte)
            let count=(status&0xf0==0xc0 || status&0xf0==0xd0) ? 1:2
            if bytes.count==count {
                if status&0xf0==0x90 && bytes[1]>0 { notes.append((Int(bytes[0]),Int(bytes[1]))) }
                bytes=[]
            }
        }
        return notes
    }
}
final class MIDIInput {
    private var client=MIDIClientRef(),port=MIDIPortRef()
    private var connected=[MIDIEndpointRef]()
    private var parsers=[MIDIEndpointRef:MIDIStreamParser]()
    var onSourceRemoved:(()->Void)?
    private let parserLock=NSLock()
    var onNote:((Int,Float,Double)->Void)?
    var onStatus:((String,Bool)->Void)?
    func start() {
        let status=MIDIClientCreateWithBlock("POCKET" as CFString,&client) { [weak self] _ in DispatchQueue.main.async { self?.refresh() } }
        guard status==noErr else { onStatus?("MIDI unavailable (\(status))",false);return }
        let result=MIDIInputPortCreateWithBlock(client,"Pads" as CFString,&port) { [weak self] list,context in
            let source=MIDIEndpointRef(UInt(bitPattern:context))
            self?.parserLock.lock()
            defer {self?.parserLock.unlock()}
            var parser=self?.parsers[source] ?? MIDIStreamParser()
            do {
                var p=UnsafeRawPointer(list).advanced(by:MemoryLayout<MIDIPacketList>.offset(of: \.packet)!).assumingMemoryBound(to:MIDIPacket.self)
                for _ in 0..<list.pointee.numPackets {
                    let value=p.pointee
                    let data=Array(UnsafeBufferPointer(start:UnsafeRawPointer(p).advanced(by:MemoryLayout<MIDIPacket>.offset(of: \.data)!).assumingMemoryBound(to:UInt8.self),count:Int(value.length)))
                    let time=value.timeStamp==0 ? AudioEngine.now:AVAudioTime.seconds(forHostTime:value.timeStamp)
                    let events=parser.feed(data)
                    for (note,velocity) in events { DispatchQueue.main.async { self?.onNote?(note,Float(velocity)/127,time) } }
                    p=UnsafePointer(MIDIPacketNext(p))
                }
            }
            self?.parsers[source]=parser
        }
        guard result==noErr else { onStatus?("MIDI input unavailable (\(result))",false);return }
        refresh()
    }
    private func refresh() {
        guard port != 0 else { return }
        let sources=(0..<MIDIGetNumberOfSources()).map { MIDIGetSource($0) }
        if connected.contains(where:{!sources.contains($0)}) { onSourceRemoved?() }
        for source in connected where !sources.contains(source) { MIDIPortDisconnectSource(port,source) }
        for source in sources where !connected.contains(source) { MIDIPortConnectSource(port,source,UnsafeMutableRawPointer(bitPattern:UInt(source))) }
        connected=sources
        let names=sources.map { source -> String in
            var name:Unmanaged<CFString>?
            MIDIObjectGetStringProperty(source,kMIDIPropertyDisplayName,&name)
            return name?.takeRetainedValue() as String? ?? "MIDI pads"
        }
        onStatus?(names.isEmpty ? "Connect a USB MIDI controller":names.joined(separator:", "),!names.isEmpty)
    }
    deinit { if port != 0 { MIDIPortDispose(port) };if client != 0 { MIDIClientDispose(client) } }
}
