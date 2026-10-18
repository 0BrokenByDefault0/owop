import SwiftUI
import UIKit

struct PadSurface:UIViewRepresentable {
    @ObservedObject var session:Session
    var full:Bool=false
    func makeUIView(context:Context)->PadView { PadView() }
    func updateUIView(_ view:PadView,context:Context) {
        let selected=full ? Array(0..<16):session.activePads
        if view.pads != selected { view.pads=selected;view.setNeedsLayout() }
        view.highlight=session.upcoming
        view.last=session.lastHitTime>AudioEngine.now-0.11 ? session.lastPad:-1
        view.positional=session.positional;view.handLabels=session.upcomingHands
        view.onHit={ pad,velocity,time in session.strike(pad,velocity:velocity,timestamp:time) }
        view.setNeedsDisplay()
    }
}
final class PadAccessibility:UIAccessibilityElement {
    var hit:(()->Void)?
    override func accessibilityActivate()->Bool { hit?();return true }
}
final class PadView:UIView {
    var pads=[Int]()
    var highlight=Set<Int>()
    var last = -1
    var positional=false
    var handLabels=[Int:String]()
    var onHit:((Int,Float,Double)->Void)?
    private var rects=[CGRect]()
    override init(frame:CGRect) {
        super.init(frame:frame)
        isMultipleTouchEnabled=true;isExclusiveTouch=false;backgroundColor = .clear
        isAccessibilityElement=false;accessibilityIdentifier="instrument-pads"
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
    override func layoutSubviews() {
        super.layoutSubviews()
        let columns=pads.count<=4 ? 2:4
        let rows=max(1,(pads.count+columns-1)/columns)
        let gap:CGFloat=pads.count<=4 ? 12:7
        let width=(bounds.width-CGFloat(columns-1)*gap)/CGFloat(columns)
        let height=(bounds.height-CGFloat(rows-1)*gap)/CGFloat(rows)
        rects=pads.indices.map { index in
            let row=index/columns,column=index%columns
            return CGRect(x:CGFloat(column)*(width+gap),y:CGFloat(rows-1-row)*(height+gap),width:width,height:height)
        }
        accessibilityElements=pads.indices.map { index in
            let element=PadAccessibility(accessibilityContainer:self)
            let pad=pads[index]
            element.accessibilityLabel="Pad \(pad+1), \(DrumPad.all[pad].name)"
            element.accessibilityHint="Double tap to play. Fixed velocity unless position dynamics is enabled."
            element.accessibilityTraits = .button
            element.accessibilityFrameInContainerSpace=rects[index]
            element.hit={ [weak self] in self?.onHit?(pad,pad==4 ? 0.3:0.8,AudioEngine.now) }
            return element
        }
        setNeedsDisplay()
    }
    override func draw(_ rect:CGRect) {
        guard let context=UIGraphicsGetCurrentContext(),rects.count==pads.count else { return }
        for (index,pad) in pads.enumerated() {
            let box=rects[index],active=pad==last,target=highlight.contains(pad),role=DrumPad.all[pad].role
            let color:UIColor=role==0 ? UIColor(red:0.98,green:0.71,blue:0.36,alpha:1):(role==1||role==6 ? UIColor(red:0.94,green:0.48,blue:0.43,alpha:1):UIColor(red:0.48,green:0.74,blue:0.75,alpha:1))
            let path=UIBezierPath(roundedRect:box.insetBy(dx:1,dy:1),cornerRadius:pads.count<=4 ? 20:12)
            UIColor(white:active ? 0.25:0.11,alpha:1).setFill();path.fill()
            color.withAlphaComponent(active ? 0.9:(target ? 0.7:0.22)).setStroke();path.lineWidth=target||active ? 2:1;path.stroke()
            let strip=CGRect(x:box.minX+12,y:box.minY+12,width:target ? 24:12,height:3)
            context.setFillColor(color.withAlphaComponent(active||target ? 1:0.7).cgColor);context.fill(strip)
            let small=pads.count>8 || box.height<100
            let titleFont=UIFont.systemFont(ofSize:small ? 11:17,weight:.semibold)
            let text=DrumPad.all[pad].short as NSString
            text.draw(in:CGRect(x:box.minX+12,y:box.maxY-(small ? 28:39),width:box.width-18,height:24),withAttributes:[.font:titleFont,.foregroundColor:UIColor(white:0.92,alpha:1)])
            if box.height>70 {
                let number="\(String(format:"%02d",pad+1))" as NSString
                number.draw(at:CGPoint(x:box.maxX-29,y:box.minY+10),withAttributes:[.font:UIFont.monospacedDigitSystemFont(ofSize:10,weight:.medium),.foregroundColor:UIColor(white:0.55,alpha:1)])
            }
            if target && box.height>85 {
                let hand=(handLabels[pad] ?? "") as NSString
                hand.draw(at:CGPoint(x:box.minX+12,y:box.minY+27),withAttributes:[.font:UIFont.systemFont(ofSize:11,weight:.medium),.foregroundColor:color])
            }
        }
    }
    override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) {
        for touch in touches {
            let point=touch.location(in:self)
            if let index=rects.firstIndex(where:{$0.contains(point)}),index<pads.count {
                let pad=pads[index]
                let fraction=Float((rects[index].maxY-point.y)/max(1,rects[index].height))
                let velocity:Float=positional ? min(1,max(0.15,0.15+fraction*0.85)):(pad==4 ? 0.3:0.8)
                onHit?(pad,velocity,touch.timestamp)
            }
        }
    }
}
