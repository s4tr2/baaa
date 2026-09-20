import SwiftUI

/// One throw, mid-flight. Driven by the keyframes in `NotchView`; the initial
/// value is "chappal tucked away in the notch, nothing happening".
struct ThrowPose {
    /// 0 = tucked behind the block, 1 = it has reached your face. Position, size
    /// and blur are all derived from this.
    var fly: Double = 0
    /// Fades to nothing at the end of the flight.
    var opacity: Double = 0
    /// Flat spin in degrees (about the axis pointing at you).
    var spin: Double = 0
    /// End-over-end tumble in degrees (about the horizontal axis).
    var tumble: Double = 0
    /// Sideways curl in points as it flies.
    var sway: Double = 0
    /// Papa leaning into the throw: 0 at rest, 1 at full lunge.
    var lunge: Double = 0
    /// Horizontal recoil applied to Papa and, scaled down, to the bubble.
    var shake: Double = 0
    /// Red edge on the bubble at the moment of impact.
    var flash: Double = 0
}

/// The classic rubber Hawai chappal, seen from above: a two-layer sole (blue
/// under, off-white on top), a blue V-strap from a toe post, and a worn heel.
/// Toe at the top, heel at the bottom.
struct ChappalView: View {
    static let size = CGSize(width: 46, height: 104)

    private let rubberBlue = Color(red: 0.12, green: 0.32, blue: 0.72)
    private let rubberBlueDark = Color(red: 0.08, green: 0.22, blue: 0.52)
    private let soleTop = Color(red: 0.95, green: 0.93, blue: 0.86)
    private let soleWorn = Color(red: 0.86, green: 0.82, blue: 0.72)
    private let strapHighlight = Color(red: 0.45, green: 0.62, blue: 0.92)

    var body: some View {
        ZStack {
            // Lower (blue) layer, showing as a rim, and its darker outer edge.
            SoleShape().fill(rubberBlueDark)
            SoleShape().fill(rubberBlue).scaleEffect(0.96)
            // Top (off-white) layer, slightly worn toward the heel and where the foot sits.
            SoleShape().fill(soleTop).scaleEffect(0.86)
            SoleShape().fill(
                RadialGradient(colors: [soleWorn.opacity(0.9), soleWorn.opacity(0)],
                               center: UnitPoint(x: 0.5, y: 0.78), startRadius: 0, endRadius: 34)
            ).scaleEffect(0.86)
            SoleShape().fill(
                RadialGradient(colors: [soleWorn.opacity(0.55), soleWorn.opacity(0)],
                               center: UnitPoint(x: 0.5, y: 0.22), startRadius: 0, endRadius: 22)
            ).scaleEffect(0.86)
            // Tread dots on the top layer, the way the moulded rubber has them.
            tread
            // V-strap from the toe post out to both sides.
            strap
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .compositingGroup()
        .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
    }

    private var tread: some View {
        Canvas { ctx, _ in
            let dot = Color(red: 0.78, green: 0.74, blue: 0.64).opacity(0.55)
            for row in 0..<11 {
                for col in 0..<4 {
                    let y = 34 + CGFloat(row) * 6
                    let x = 14 + CGFloat(col) * 6 + (row % 2 == 0 ? 0 : 3)
                    // Keep them off the strap and inside the arch.
                    guard y > 62 || abs(x - 23) < 5 else { continue }
                    guard x > 10, x < 36 else { continue }
                    ctx.fill(Path(ellipseIn: CGRect(x: x - 0.9, y: y - 0.9, width: 1.8, height: 1.8)), with: .color(dot))
                }
            }
        }
    }

    private var strap: some View {
        ZStack {
            StrapShape().stroke(rubberBlueDark, style: StrokeStyle(lineWidth: 7.5, lineCap: .round))
            StrapShape().stroke(rubberBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
            StrapShape().stroke(strapHighlight.opacity(0.55), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                .offset(x: -0.8, y: -0.8)
            // Toe post.
            Circle().fill(rubberBlueDark).frame(width: 7, height: 7).position(x: 23, y: 27)
            Circle().fill(rubberBlue).frame(width: 5, height: 5).position(x: 23, y: 27)
        }
    }
}

/// Footprint-ish outline in a 46 x 104 box: broad rounded toe at the top, a
/// slight arch on the inner (left) side, narrower rounded heel at the bottom.
struct SoleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 46, sy = rect.height / 104
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy) }
        var p = Path()
        p.move(to: P(4, 28))
        // Toe cap
        p.addCurve(to: P(42, 28), control1: P(3, -4), control2: P(43, -4))
        // Outer edge down to the heel
        p.addCurve(to: P(38, 92), control1: P(43, 48), control2: P(40, 74))
        // Heel
        p.addCurve(to: P(12, 92), control1: P(37, 108), control2: P(13, 108))
        // Inner edge with the arch
        p.addCurve(to: P(4, 28), control1: P(10, 74), control2: P(7, 52))
        p.closeSubpath()
        return p
    }
}

/// The V-strap: from the toe post out and back to each side of the sole.
struct StrapShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 46, sy = rect.height / 104
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy) }
        var p = Path()
        p.move(to: P(23, 27))
        p.addCurve(to: P(41, 58), control1: P(30, 30), control2: P(40, 44))
        p.move(to: P(23, 27))
        p.addCurve(to: P(5, 58), control1: P(16, 30), control2: P(6, 44))
        return p
    }
}
