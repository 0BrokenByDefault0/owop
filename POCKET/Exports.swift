import Foundation

struct StateStore {
    static var folder:URL { FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0] }
    static var url:URL { folder.appendingPathComponent("pocket-state.json") }
    static func load() throws -> SavedState {
        guard FileManager.default.fileExists(atPath:url.path) else { return SavedState() }
        let data=try Data(contentsOf:url)
        do { return try JSONDecoder().decode(SavedState.self,from:data) }
        catch {
            let backup=folder.appendingPathComponent("pocket-recovery-\(Int(Date().timeIntervalSince1970)).json")
            try? data.write(to:backup,options:.atomic)
            throw error
        }
    }
    static func save(_ value:SavedState) throws {
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        try JSONEncoder().encode(value).write(to:url,options:.atomic)
    }
}
struct TakeExporter {
    static let notes=[36,36,42,38,38,38,46,42,75,82,39,37,49,51,50,45]
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
        for hit in take.hits where hit.time>=0 && hit.pad>=0 && hit.pad<16 {
            let tick=Int((hit.time*Double(bpm)/60*480).rounded())
            let velocity=UInt8(max(1,min(127,Int(hit.velocity*127))))
            events.append((tick,[0x99,UInt8(notes[hit.pad]),velocity]))
            events.append((tick+24,[0x89,UInt8(notes[hit.pad]),0]))
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
        let hits=take.hits.filter { $0.time.isFinite && $0.time>=0 && $0.pad>=0 && $0.pad<16 }.sorted{$0.time<$1.time}
        let frames=Int((take.duration+1.2)*rate)
        var pcm=Data(capacity:frames*4),index=0
        var left=[Float](repeating:0,count:512),right=left
        for start in stride(from:0,to:frames,by:512) {
            let count=min(512,frames-start),time=Double(start)/rate
            while index<hits.count && hits[index].time<time+Double(count)/rate {
                let hit=hits[index];_ = pd_enqueue(kernel,Int32(hit.pad),hit.velocity,hit.time,Int32(take.kit));index+=1
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
