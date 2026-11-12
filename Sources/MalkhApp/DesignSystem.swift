import AppKit
import SwiftUI

// One shared visual language, with native light/dark appearance and motion preferences.
enum MalkhPalette {
    static func adaptive(_ light:(Double,Double,Double),_ dark:(Double,Double,Double))->NSColor {
        NSColor(name:nil) { appearance in
            let rgb=appearance.bestMatch(from:[.darkAqua,.aqua]) == .darkAqua ? dark:light
            return NSColor(srgbRed:rgb.0,green:rgb.1,blue:rgb.2,alpha:1)
        }
    }
    // Malkh paleti: İnguş bayrağından yeşil + beyaz, kırmızı yalnızca vurgu/hata için.
    static let canvas=Color(nsColor:adaptive((0.961,0.973,0.965),(0.071,0.078,0.075)))
    static let surface=Color(nsColor:adaptive((1,1,1),(0.114,0.122,0.118)))
    static let inset=Color(nsColor:adaptive((0.933,0.949,0.937),(0.090,0.098,0.094)))
    static let forest=Color(nsColor:adaptive((0.086,0.400,0.220),(0.553,0.851,0.651)))
    static let sand=Color(nsColor:adaptive((0.910,0.961,0.925),(0.098,0.200,0.137)))
    static let sage=Color(nsColor:adaptive((0.878,0.945,0.898),(0.110,0.212,0.149)))
    static let border=Color.primary.opacity(0.08)
    static let gold=MalkhArtwork.gold
    static let ink=MalkhArtwork.ink
    static let goldInk=Color(nsColor:adaptive((0.078,0.420,0.224),(0.553,0.878,0.659)))
    static let buttonInk=Color.white
    static let alert=Color(nsColor:adaptive((0.839,0.157,0.157),(1.0,0.420,0.420)))
    static let goldEnd=Color(nsColor:adaptive((0.196,0.651,0.396),(0.333,0.780,0.510)))
}
extension Color { static let malkh=Color(nsColor:MalkhPalette.gold) }

enum MalkhMotion {
    static var enabled:Bool { !UserDefaults.standard.bool(forKey:"reduceAnimations") && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
}
enum MalkhAppearance {
    @MainActor static func apply(_ choice:String?=nil) {
        let choice=choice ?? UserDefaults.standard.string(forKey:"appAppearance") ?? "system"
        NSApp.appearance=choice=="light" ? NSAppearance(named:.aqua):choice=="dark" ? NSAppearance(named:.darkAqua):nil
    }
}

struct MalkhMotionModifier<Value:Equatable>:ViewModifier {
    let value:Value
    @Environment(\.accessibilityReduceMotion) private var systemReduced
    @AppStorage("reduceAnimations") private var reduced=false
    func body(content:Content)->some View { content.animation(systemReduced || reduced ? nil:.spring(response:0.32,dampingFraction:0.88),value:value) }
}
struct MalkhEntrance:ViewModifier {
    var delay=0.0
    @State private var visible=false
    @Environment(\.accessibilityReduceMotion) private var systemReduced
    @AppStorage("reduceAnimations") private var reduced=false
    func body(content:Content)->some View {
        content.opacity(visible ? 1:0).offset(y:visible || systemReduced || reduced ? 0:8)
            .onAppear {
                if systemReduced || reduced { visible=true }
                else { withAnimation(.easeOut(duration:0.24).delay(delay)) { visible=true } }
            }
    }
}
extension View {
    func malkhAnimation<V:Equatable>(value:V)->some View { modifier(MalkhMotionModifier(value:value)) }
    func malkhEntrance(delay:Double=0)->some View { modifier(MalkhEntrance(delay:delay)) }
    func malkhCard(radius:CGFloat=22)->some View {
        background(MalkhPalette.surface,in:RoundedRectangle(cornerRadius:radius,style:.continuous))
            .overlay(RoundedRectangle(cornerRadius:radius,style:.continuous).strokeBorder(MalkhPalette.border,lineWidth:1))
    }
}

enum MalkhButtonKind { case primary,secondary,quiet }
struct MalkhButtonStyle:ButtonStyle {
    var kind:MalkhButtonKind = .secondary
    var compact=false
    init(_ kind:MalkhButtonKind = .secondary,compact:Bool=false) { self.kind=kind;self.compact=compact }
    func makeBody(configuration:Configuration)->some View { MalkhButtonBody(configuration:configuration,kind:kind,compact:compact) }
}
private struct MalkhButtonBody:View {
    let configuration:ButtonStyleConfiguration
    let kind:MalkhButtonKind
    let compact:Bool
    @State private var hovered=false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.isFocused) private var focused
    @Environment(\.accessibilityReduceMotion) private var systemReduced
    @AppStorage("reduceAnimations") private var reduced=false
    private var primary:Bool { kind == .primary }
    var body:some View {
        configuration.label.font(.system(size:compact ? 11:13,weight:.semibold,design:.rounded))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal:false,vertical:true)
            .frame(minHeight:compact ? 14:18,alignment:.center)
            .padding(.horizontal,compact ? 10:15).padding(.vertical,compact ? 7:11)
            .foregroundStyle(primary ? MalkhPalette.buttonInk:Color.primary)
            .background {
                RoundedRectangle(cornerRadius:compact ? 10:13,style:.continuous)
                    .fill(primary ? AnyShapeStyle(LinearGradient(colors:[Color.malkh,MalkhPalette.goldEnd],startPoint:.leading,endPoint:.trailing)):AnyShapeStyle(kind == .quiet ? Color.clear:MalkhPalette.surface))
                    .overlay(RoundedRectangle(cornerRadius:compact ? 10:13,style:.continuous).strokeBorder(primary ? Color.white.opacity(0.12):MalkhPalette.border,lineWidth:kind == .quiet ? 0:1))
            }
            .overlay(RoundedRectangle(cornerRadius:compact ? 10:13).fill(Color.primary.opacity(hovered && !primary ? 0.035:0)))
            .overlay(RoundedRectangle(cornerRadius:compact ? 10:13).strokeBorder(focused ? MalkhPalette.goldInk:Color.clear,lineWidth:2).padding(-3))
            .shadow(color:primary && enabled ? Color.malkh.opacity(hovered ? 0.20:0.10):.clear,radius:hovered ? 9:5,y:3)
            .scaleEffect(systemReduced || reduced ? 1:configuration.isPressed ? 0.97:hovered && enabled ? 1.015:1)
            .opacity(enabled ? 1:0.4).contentShape(RoundedRectangle(cornerRadius:13))
            .onHover { hovered=$0 }
            .animation(systemReduced || reduced ? nil:.easeOut(duration:0.14),value:configuration.isPressed)
            .animation(systemReduced || reduced ? nil:.easeOut(duration:0.16),value:hovered)
    }
}
struct MalkhGroupBoxStyle:GroupBoxStyle {
    func makeBody(configuration:Configuration)->some View {
        VStack(alignment:.leading,spacing:16) {
            configuration.label.font(.system(size:13,weight:.semibold,design:.rounded)).foregroundStyle(MalkhPalette.forest)
            configuration.content
        }.padding(20).frame(maxWidth:.infinity,alignment:.leading).malkhCard()
    }
}

struct MalkhMark:View {
    var size:CGFloat=44
    var happy=false
    var body:some View {
        Image(nsImage:MalkhArtwork.mark(size:size*2,happy:happy)).resizable().interpolation(.high).frame(width:size,height:size).accessibilityHidden(true)
    }
}

struct MalkhPill:View {
    let title:String
    var symbol:String?=nil
    var color:Color=MalkhPalette.forest
    var body:some View {
        HStack(spacing:5) { if let symbol { Image(systemName:symbol) };LText(title) }
            .font(.system(size:10,weight:.semibold,design:.rounded)).foregroundStyle(color == .malkh ? MalkhPalette.goldInk:color)
            .padding(.horizontal,9).padding(.vertical,5).background(color.opacity(0.09),in:Capsule())
    }
}
struct MalkhPageHeading:View {
    let eyebrow:String
    let title:String
    let subtitle:String
    var body:some View {
        VStack(alignment:.leading,spacing:8) {
            LText(eyebrow.uppercased()).font(.system(size:10,weight:.bold,design:.rounded)).tracking(1.4).foregroundStyle(MalkhPalette.goldInk)
            LText(title).font(.system(size:27,weight:.bold,design:.rounded)).tracking(-0.7)
            LText(subtitle).font(.system(size:12)).foregroundStyle(.secondary).fixedSize(horizontal:false,vertical:true)
        }
    }
}
struct MalkhCheck:View {
    @State private var arrived=false
    var body:some View {
        Image(systemName:"checkmark").font(.system(size:14,weight:.bold)).foregroundStyle(MalkhPalette.forest)
            .frame(width:34,height:34).background(MalkhPalette.sage,in:Circle())
            .scaleEffect(arrived ? 1:0.75).opacity(arrived ? 1:0)
            .malkhAnimation(value:arrived).onAppear{arrived=true}.accessibilityHidden(true)
    }
}
