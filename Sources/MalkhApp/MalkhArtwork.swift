import AppKit

/// Shared vector artwork: the app, menu bar, installer icon and brand exports
/// all draw the same Malkh sun — a ring with three swirling arms, after the
/// Ingush solar sign — on a green disc.
enum MalkhArtwork {
    static let gold=NSColor(name:nil) { appearance in
        appearance.bestMatch(from:[.darkAqua,.aqua]) == .darkAqua
            ? NSColor(srgbRed:0.247,green:0.718,blue:0.443,alpha:1)
            : NSColor(srgbRed:0.118,green:0.557,blue:0.306,alpha:1)
    }
    static let ink=NSColor(srgbRed:0.059,green:0.231,blue:0.129,alpha:1)
    static let green=NSColor(srgbRed:0.118,green:0.557,blue:0.306,alpha:1)
    static let lightGreen=NSColor(srgbRed:0.243,green:0.722,blue:0.431,alpha:1)

    /// The solar sign in unit coordinates (y grows downward): a small ring with
    /// three arms that curl outward from it, after the Ingush solar sign.
    static func signPath(ring r1:CGFloat=0.14,reach r2:CGFloat=0.36,turn alpha:CGFloat=80*CGFloat.pi/180)->CGPath {
        let p=CGMutablePath();let c=CGPoint(x:0.5,y:0.5)
        p.addEllipse(in:CGRect(x:c.x-r1,y:c.y-r1,width:2*r1,height:2*r1))
        for k in 0..<3 {
            let theta = -CGFloat.pi/2 + CGFloat(k)*2*CGFloat.pi/3
            let a=CGPoint(x:c.x+r1*cos(theta),y:c.y+r1*sin(theta))
            let b=CGPoint(x:c.x+r2*cos(theta+alpha),y:c.y+r2*sin(theta+alpha))
            let mid=CGPoint(x:(a.x+b.x)/2,y:(a.y+b.y)/2)
            let start=atan2(a.y-mid.y,a.x-mid.x)
            p.move(to:a)
            p.addArc(center:mid,radius:hypot(b.x-a.x,b.y-a.y)/2,startAngle:start,endAngle:start+CGFloat.pi,clockwise:false)
        }
        return p
    }
    /// Draws only the sign, in one colour, inside `rect`.
    static func drawSign(in rect:NSRect,color:NSColor,lineWidth:CGFloat=0.07) {
        guard let c=NSGraphicsContext.current?.cgContext else { return }
        c.saveGState();defer{c.restoreGState()}
        c.translateBy(x:rect.minX,y:rect.maxY);c.scaleBy(x:rect.width,y:-rect.height)
        c.setStrokeColor(color.cgColor);c.setLineWidth(lineWidth);c.setLineCap(.round);c.setLineJoin(.round)
        c.addPath(signPath());c.strokePath()
    }
    /// The full mark: green disc with a white sun. `happy` is kept for callers; the mark has one face.
    static func draw(in rect:NSRect,happy:Bool=false,monochrome:Bool=false) {
        if monochrome { drawSign(in:rect.insetBy(dx:rect.width*0.02,dy:rect.height*0.02),color:.black,lineWidth:0.10);return }
        guard let c=NSGraphicsContext.current?.cgContext else { return }
        c.saveGState()
        c.translateBy(x:rect.minX,y:rect.maxY);c.scaleBy(x:rect.width,y:-rect.height)
        let disc=CGRect(x:0.04,y:0.04,width:0.92,height:0.92)
        c.addEllipse(in:disc);c.clip()
        let colors=[lightGreen.cgColor,green.cgColor] as CFArray
        let gradient=CGGradient(colorsSpace:CGColorSpace(name:CGColorSpace.sRGB),colors:colors,locations:[0,1])!
        c.drawLinearGradient(gradient,start:CGPoint(x:0.2,y:0.1),end:CGPoint(x:0.8,y:0.95),options:[.drawsBeforeStartLocation,.drawsAfterEndLocation])
        c.restoreGState()
        drawSign(in:rect,color:.white)
    }
    static func mark(size:CGFloat,happy:Bool=false)->NSImage {
        NSImage(size:NSSize(width:size,height:size),flipped:false) { rect in draw(in:rect,happy:happy);return true }
    }
    static func menuIcon(updateAvailable:Bool=false)->NSImage {
        let image=NSImage(size:NSSize(width:20,height:20),flipped:false) { rect in
            draw(in:rect.insetBy(dx:0.5,dy:0.5),monochrome:true)
            if updateAvailable { NSColor.black.setFill();NSBezierPath(ovalIn:NSRect(x:15,y:15,width:4,height:4)).fill() }
            return true
        }
        image.isTemplate=true;image.accessibilityDescription=updateAvailable ? "Malkh update available":"Malkh";return image
    }
}
