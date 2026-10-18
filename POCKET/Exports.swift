import Foundation

struct StateStore {
    static var folder:URL { FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0] }
    static var url:URL { folder.appendingPathComponent("pocket-state.json") }
    static var backup:URL { folder.appendingPathComponent("pocket-state.backup.json") }
    static var recoveryNotice:String?
    static func decode(_ data:Data)throws->SavedState {
        let state=try JSONDecoder().decode(SavedState.self,from:data)
        guard state.progress.keys.allSatisfy({(0..<24).contains($0)}),state.takes.count<=50,
              state.takes.allSatisfy({ take in
                  (30...180).contains(take.bpm) && (0...1).contains(take.kit) && take.duration.isFinite && (0...300).contains(take.duration) && take.hits.count<=50000 &&
                  (take.padNotes==nil || (take.padNotes!.count==16 && take.padNotes!.allSatisfy{(0...127).contains($0)})) &&
                  take.hits.allSatisfy { hit in
                      (0..<16).contains(hit.pad) && hit.time.isFinite && (-0.35...301).contains(hit.time) && hit.velocity.isFinite && (0...1).contains(hit.velocity) && (hit.sourceNote==nil || (0...127).contains(hit.sourceNote!)) && (hit.assessmentTime==nil || hit.assessmentTime!.isFinite)
                  }
              }) else { throw TakeExporter.ExportError.invalid }
        return state
    }
    static func load() throws -> SavedState {
        recoveryNotice=nil
        guard FileManager.default.fileExists(atPath:url.path) else {
            if let data=try? Data(contentsOf:backup),let recovered=try? decode(data) { recoveryNotice="Your progress was restored from the last valid backup.";return recovered }
            return SavedState()
        }
        let data=try Data(contentsOf:url)
        do { return try decode(data) }
        catch {
            let copy=folder.appendingPathComponent("pocket-recovery-\(Int(Date().timeIntervalSince1970)).json")
            try? data.write(to:copy,options:.atomic)
            if let data=try? Data(contentsOf:backup),let recovered=try? decode(data) {
                recoveryNotice="Your progress was restored from the last valid backup. The damaged file was kept separately."
                return recovered
            }
            throw error
        }
    }
    static func save(_ value:SavedState) throws {
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        let data=try JSONEncoder().encode(value)
        _ = try decode(data)
        if let previous=try? Data(contentsOf:url),(try? decode(previous)) != nil { try previous.write(to:backup,options:.atomic) }
        try data.write(to:url,options:.atomic)
    }
}
struct TakeExporter {
    static let notes=[36,35,42,38,38,38,46,42,75,82,39,37,49,51,50,45]
    static func vlq(_ number:Int)->[UInt8] {
        var n=max(0,number),bytes=[UInt8(n&0x7f)];n >>= 7
        while n>0 { bytes.insert(UInt8(n&0x7f)|0x80,at:0);n >>= 7 }
        return bytes
    }
    static func midi(_ take:Take)->Data {
        let bpm=max(30,min(240,take.bpm))
        let tempo=60000000/bpm
        var track=Data([0,0xff,0x51,3,UInt8((tempo>>16)&255),UInt8((tempo>>8)&255),UInt8(tempo&255)])
        var events=[(Int,[UInt8])]()
        let preRoll=max(0,-(take.hits.map(\.time).min() ?? 0))
        for hit in take.hits where hit.time.isFinite && hit.pad>=0 && hit.pad<16 {
            let tick=Int(((hit.time+preRoll)*Double(bpm)/60*480).rounded())
            let velocity=UInt8(max(1,min(127,Int(hit.velocity*127))))
            let note=UInt8(max(0,min(127,hit.sourceNote ?? take.padNotes?[hit.pad] ?? notes[hit.pad])))
            events.append((tick,[0x99,note,velocity]))
            events.append((tick+24,[0x89,note,0]))
        }
        events.sort { $0.0 == $1.0 ? $0.1[0] < $1.1[0] : $0.0 < $1.0 }
        var last=0
        for (tick,message) in events { track.append(contentsOf:vlq(tick-last));track.append(contentsOf:message);last=tick }
        track.append(contentsOf:[0,0xff,0x2f,0])
        var file=Data("MThd".utf8)
        func be(_ x:UInt32)->[UInt8] { [UInt8((x>>24)&255),UInt8((x>>16)&255),UInt8((x>>8)&255),UInt8(x&255)] }
        file.append(contentsOf:be(6));file.append(contentsOf:[0,0,0,1,1,0xe0]);file.append(Data("MTrk".utf8));file.append(contentsOf:be(UInt32(track.count)));file.append(track)
        return file
    }
    static func wav(_ take:Take)throws->Data {
        let rate=48000.0
        guard take.duration.isFinite,take.duration>=0,take.duration<=300,let kernel=pd_create(rate) else { throw ExportError.invalid }
        defer { pd_destroy(kernel) }
        let hits=take.hits.filter { $0.time.isFinite && $0.pad>=0 && $0.pad<16 }.sorted{$0.time<$1.time}
        let preRoll=max(0,-(hits.first?.time ?? 0))
        let frames=Int((take.duration+preRoll+1.2)*rate)
        var pcm=Data(capacity:frames*4),index=0
        var left=[Float](repeating:0,count:512),right=left
        for start in stride(from:0,to:frames,by:512) {
            let count=min(512,frames-start),time=Double(start)/rate
            while index<hits.count && hits[index].time+preRoll<time+Double(count)/rate {
                let hit=hits[index];_ = pd_enqueue(kernel,Int32(hit.pad),hit.velocity,hit.time+preRoll,Int32(take.kit));index+=1
            }
            left.withUnsafeMutableBufferPointer { l in right.withUnsafeMutableBufferPointer { r in pd_render(kernel,l.baseAddress,r.baseAddress,Int32(count),time) } }
            for i in 0..<count { for x in [left[i],right[i]] { var sample=Int16(max(-32767,min(32767,Int(x*32767)))).littleEndian;withUnsafeBytes(of:&sample){pcm.append(contentsOf:$0)} } }
        }
        var data=Data()
        func text(_ s:String) { data.append(Data(s.utf8)) }
        func le<T:FixedWidthInteger>(_ v:T) { var x=v.littleEndian;withUnsafeBytes(of:&x){data.append(contentsOf:$0)} }
        text("RIFF");le(UInt32(36+pcm.count));text("WAVEfmt ");le(UInt32(16));le(UInt16(1));le(UInt16(2));le(UInt32(rate));le(UInt32(rate)*4);le(UInt16(4));le(UInt16(16));text("data");le(UInt32(pcm.count));data.append(pcm)
        return data
    }
    static func file(_ take:Take,wave:Bool)throws->URL {
        let url=FileManager.default.temporaryDirectory.appendingPathComponent("POCKET-\(take.id.uuidString.prefix(8)).\(wave ? "wav":"mid")")
        let data=try wave ? wav(take):midi(take)
        try data.write(to:url,options:.atomic)
        return url
    }
    enum ExportError:Error { case invalid }
}
