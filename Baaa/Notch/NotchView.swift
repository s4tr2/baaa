import SwiftUI

/// Papa peeks out of a black block that grows from the notch; his line sits in a
/// white speech bubble beside it, with an English gloss underneath when there is one.
struct NotchView: View {
    @ObservedObject var model: NotchViewModel

    private var blockWidth: CGFloat { NotchController.blockWidth(forNotch: model.notchWidth) }
    private var flare: CGFloat { NotchController.flare }
    private var bodyHeight: CGFloat { NotchController.blockBodyHeight }
    private var bubbleWidth: CGFloat { NotchController.bubbleWidth }
    private var accent: Color { Color(red: 1.0, green: 0.62, blue: 0.20) }

    /// The block frame includes room for the flares, but the black body is narrower,
    /// so pull the bubble back so its tail nearly touches the body.
    private var bubbleSpacing: CGFloat { model.hasNotch ? NotchController.bubbleGap - flare : NotchController.bubbleGap }

    var body: some View {
        HStack(alignment: .top, spacing: bubbleSpacing) {
            block
                .frame(width: blockWidth + flare * 2, alignment: .center)
            bubble
                .padding(.top, model.hasNotch ? model.notchHeight + 8 : 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onHover { model.hovering = $0 }
    }

    // MARK: - Block with Papa

    private var block: some View {
        let expanded = model.expanded
        let topHeight = model.hasNotch ? model.notchHeight : 0
        let width: CGFloat = model.hasNotch ? (expanded ? blockWidth : model.notchWidth) : (expanded ? blockWidth : 60)
        let height: CGFloat = expanded ? topHeight + bodyHeight : (model.hasNotch ? model.notchHeight : 8)
        let shapeFlare: CGFloat = model.hasNotch && expanded ? flare : 0
        let shape = BlockShape(hasNotch: model.hasNotch, flare: shapeFlare, radius: 26)

        return ZStack(alignment: .bottom) {
            PeekingPapaView(config: model.avatar,
                            expression: model.nudge?.expression ?? .neutral,
                            image: model.image,
                            moodImage: model.moodImage,
                            moodOpacity: model.moodRevealed ? 1 : 0,
                            width: blockWidth - 16,
                            height: bodyHeight - 4)
                .modifier(IdleSway())
                .padding(.bottom, 2)
                // Comes down out of the notch, retracts back up into it.
                .offset(y: expanded ? 0 : -(bodyHeight + 10))
                .opacity(expanded ? 1 : 0.6)
        }
        .frame(width: width + shapeFlare * 2, height: height, alignment: .bottom)
        .background(shape.fill(.black))
        .clipShape(shape)
        .compositingGroup()
        .shadow(color: .black.opacity(expanded ? 0.35 : 0), radius: 16, y: 8)
        .frame(height: topHeight + bodyHeight, alignment: .top)
        .contentShape(Rectangle())
        .onTapGesture { model.onOpenSettings?() }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { model.blockRect = $0 }
    }

    // MARK: - Speech bubble

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(model.nudge?.speaker ?? "Papa")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(accent)
                .lineLimit(1)
            Text(model.nudge?.message ?? "")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(white: 0.08))
                .fixedSize(horizontal: false, vertical: true)
            if let sub = model.nudge?.subtitle, !sub.isEmpty {
                Text(sub)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(white: 0.46))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if model.hovering {
                HStack(spacing: 8) {
                    BubbleButton(title: model.doneLabel, prominent: true) { model.onDone?() }
                    BubbleButton(title: model.snoozeLabel, prominent: false) { model.onSnooze?() }
                }
                .padding(.top, 6)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.leading, 18 + BubbleShape.tailLength)
        .padding(.trailing, 20)
        .padding(.vertical, 15)
        .frame(width: bubbleWidth, alignment: .leading)
        .background(
            BubbleShape(cornerRadius: 22, tailY: 50)
                .fill(.white)
                .shadow(color: .black.opacity(0.22), radius: 18, y: 8)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: model.hovering)
        .scaleEffect(model.expanded ? 1 : 0.3, anchor: .init(x: 0, y: 0.15))
        .opacity(model.expanded ? 1 : 0)
        .contentShape(BubbleShape(cornerRadius: 22, tailY: 50))
        .onTapGesture { model.onDone?() }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { model.bubbleRect = $0 }
    }
}

/// A slow, tiny sway so a still picture reads as alive.
private struct IdleSway: ViewModifier {
    @State private var phase = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(phase ? 1.4 : -1.4), anchor: .bottom)
            .offset(y: phase ? -1.5 : 1.0)
            .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: phase)
            .onAppear { phase = true }
    }
}

private struct BubbleButton: View {
    let title: String
    let prominent: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(prominent
                                   ? Color(red: 1.0, green: 0.62, blue: 0.20).opacity(hovering ? 1 : 0.92)
                                   : Color(white: hovering ? 0.86 : 0.92))
                )
                .foregroundStyle(prominent ? .black : Color(white: 0.2))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// Speech bubble drawn as one outline: rounded body with a curved comic tail on
/// the left, pointing slightly down toward Papa's mouth.
struct BubbleShape: Shape {
    static let tailLength: CGFloat = 16
    var cornerRadius: CGFloat
    var tailY: CGFloat

    func path(in rect: CGRect) -> Path {
        let t = Self.tailLength
        let r = cornerRadius
        let b = CGRect(x: rect.minX + t, y: rect.minY, width: rect.width - t, height: rect.height)
        let ty = min(max(tailY, r + 12), b.maxY - r - 12)

        var p = Path()
        p.move(to: CGPoint(x: b.minX, y: b.minY + r))
        // Down the left edge to the tail
        p.addLine(to: CGPoint(x: b.minX, y: ty - 12))
        p.addCurve(to: CGPoint(x: b.minX - t, y: ty + 6),
                   control1: CGPoint(x: b.minX - t * 0.15, y: ty - 6),
                   control2: CGPoint(x: b.minX - t * 0.6, y: ty))
        p.addCurve(to: CGPoint(x: b.minX, y: ty + 12),
                   control1: CGPoint(x: b.minX - t * 0.55, y: ty + 9),
                   control2: CGPoint(x: b.minX - t * 0.2, y: ty + 12))
        p.addLine(to: CGPoint(x: b.minX, y: b.maxY - r))
        p.addArc(center: CGPoint(x: b.minX + r, y: b.maxY - r), radius: r,
                 startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
        p.addLine(to: CGPoint(x: b.maxX - r, y: b.maxY))
        p.addArc(center: CGPoint(x: b.maxX - r, y: b.maxY - r), radius: r,
                 startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
        p.addLine(to: CGPoint(x: b.maxX, y: b.minY + r))
        p.addArc(center: CGPoint(x: b.maxX - r, y: b.minY + r), radius: r,
                 startAngle: .degrees(0), endAngle: .degrees(-90), clockwise: true)
        p.addLine(to: CGPoint(x: b.minX + r, y: b.minY))
        p.addArc(center: CGPoint(x: b.minX + r, y: b.minY + r), radius: r,
                 startAngle: .degrees(-90), endAngle: .degrees(-180), clockwise: true)
        p.closeSubpath()
        return p
    }
}

/// The black block: notch-flared when anchored to a real notch, plain rounded otherwise.
struct BlockShape: Shape {
    var hasNotch: Bool
    var flare: CGFloat
    var radius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(flare, radius) }
        set { flare = newValue.first; radius = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        if hasNotch {
            return NotchShape(flare: flare, bottomRadius: radius).path(in: rect)
        }
        return Path(roundedRect: rect, cornerRadius: min(radius, rect.height / 2), style: .continuous)
    }
}

/// Flush with the top edge, flared "ears" at the top corners like the real notch,
/// rounded at the bottom.
struct NotchShape: Shape {
    var flare: CGFloat
    var bottomRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(flare, bottomRadius) }
        set { flare = newValue.first; bottomRadius = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(bottomRadius, rect.height / 2, (rect.width - flare * 2) / 2)
        let left = rect.minX + flare
        let right = rect.maxX - flare

        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        if flare > 0 {
            p.addQuadCurve(to: CGPoint(x: left, y: rect.minY + flare), control: CGPoint(x: left, y: rect.minY))
        }
        p.addLine(to: CGPoint(x: left, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: left + r, y: rect.maxY - r), radius: r,
                 startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
        p.addLine(to: CGPoint(x: right - r, y: rect.maxY))
        p.addArc(center: CGPoint(x: right - r, y: rect.maxY - r), radius: r,
                 startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
        p.addLine(to: CGPoint(x: right, y: rect.minY + flare))
        if flare > 0 {
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: right, y: rect.minY))
        }
        p.closeSubpath()
        return p
    }
}
