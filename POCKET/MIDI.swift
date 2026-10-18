import Foundation
import CoreMIDI
import AVFoundation

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
                    let length=Int(p.pointee.length),stamp=p.pointee.timeStamp
                    let data=Array(UnsafeBufferPointer(start:UnsafeRawPointer(p).advanced(by:MemoryLayout<MIDIPacket>.offset(of: \.data)!).assumingMemoryBound(to:UInt8.self),count:length))
                    let time=stamp==0 ? AudioEngine.now:AVAudioTime.seconds(forHostTime:stamp)
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
