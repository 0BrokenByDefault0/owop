import AVFoundation
import Foundation

final class AudioEngine {
    private var engine=AVAudioEngine()
    private var source:AVAudioSourceNode?
    private var core:OpaquePointer?
    private(set) var ready=false
    private(set) var route=""
    private(set) var bufferMs=0.0
    private(set) var latencyMs=0.0
    private(set) var sampleRate=48000.0
    static var now:Double { AVAudioTime.seconds(forHostTime:mach_absolute_time()) }
    func prepare() throws {
        ready=false
        engine.stop()
        if let source { engine.detach(source) }
        source=nil
        if let core { pd_destroy(core) }
        core=nil
        let session=AVAudioSession.sharedInstance()
        try session.setCategory(.playback,mode:.default,options:[])
        try session.setPreferredSampleRate(48000)
        try session.setPreferredIOBufferDuration(0.005)
        try session.setActive(true)
        sampleRate=session.sampleRate
        bufferMs=session.ioBufferDuration*1000
        latencyMs=session.outputLatency*1000
        route=session.currentRoute.outputs.map{$0.portName}.joined(separator:", ")
        guard let kernel=pd_create(sampleRate),let format=AVAudioFormat(standardFormatWithSampleRate:sampleRate,channels:2) else { throw AudioError.unavailable }
        core=kernel
        let node=AVAudioSourceNode(format:format) { _,timestamp,frames,buffers in
            let list=UnsafeMutableAudioBufferListPointer(buffers)
            guard list.count>=2,let left=list[0].mData?.assumingMemoryBound(to:Float.self),let right=list[1].mData?.assumingMemoryBound(to:Float.self) else { return -1 }
            let host=AVAudioTime.seconds(forHostTime:timestamp.pointee.mHostTime)
            pd_render(kernel,left,right,Int32(frames),host)
            return noErr
        }
        source=node
        engine.attach(node)
        engine.connect(node,to:engine.mainMixerNode,format:format)
        engine.prepare()
        try engine.start()
        ready=true
    }
    @discardableResult func play(_ pad:Int,velocity:Float=0.8,at time:Double?=nil,kit:Int=0)->Bool {
        guard ready,let core else { return false }
        return pd_enqueue(core,Int32(pad),velocity,time ?? Self.now,Int32(kit)) != 0
    }
    func cancel() { if let core { pd_cancel(core) } }
    var routeKey:String { AVAudioSession.sharedInstance().currentRoute.outputs.map{$0.uid}.joined(separator:"|") }
    var wireless:Bool { AVAudioSession.sharedInstance().currentRoute.outputs.contains { [.bluetoothA2DP,.bluetoothHFP,.bluetoothLE,.airPlay].contains($0.portType) } }
    deinit { engine.stop();if let core { pd_destroy(core) } }
    enum AudioError:Error { case unavailable }
}
