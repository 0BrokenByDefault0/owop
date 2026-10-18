import Foundation

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
