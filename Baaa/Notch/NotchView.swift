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
        // Each bump of `chappalThrows` flings the chappal once: it slides out from behind
        // the block, then flies straight at you, tumbling, growing and blurring, and is gone.
        // Launch is at 0.18s, impact at 0.55s; NotchController's sound matches.
        KeyframeAnimator(initialValue: ThrowPose(), trigger: model.chappalThrows) { pose in
            HStack(alignment: .top, spacing: bubbleSpacing) {
                block(pose)
                    .frame(width: blockWidth + flare * 2, alignment: .center)
                bubble(pose)
                    .padding(.top, model.hasNotch ? model.notchHeight + 8 : 10)
            }
            .padding(.leading, sidePad)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .overlay(alignment: .topLeading) { thrownChappal(pose) }
            .onHover { model.hovering = $0 }
        } keyframes: { _ in
            KeyframeTrack(\.fly) {
                CubicKeyframe(0.10, duration: 0.18)   // edges out of the notch
                CubicKeyframe(1.0, duration: 0.37)    // then straight at you
                LinearKeyframe(1.0, duration: 0.35)
            }
            KeyframeTrack(\.opacity) {
                LinearKeyframe(1, duration: 0.02)
                LinearKeyframe(1, duration: 0.44)
                LinearKeyframe(0, duration: 0.14)     // oblivion
                LinearKeyframe(0, duration: 0.30)
            }
            // Tumbling end over end (about the x axis) while spinning flat (about z).
            KeyframeTrack(\.tumble) {
                CubicKeyframe(20, duration: 0.18)
                LinearKeyframe(560, duration: 0.37)
                LinearKeyframe(560, duration: 0.35)
            }
            KeyframeTrack(\.spin) {
                CubicKeyframe(-12, duration: 0.18)
                CubicKeyframe(310, duration: 0.37)
                LinearKeyframe(310, duration: 0.35)
            }
            // A slight arc to one side, the way a thrown chappal curls.
            KeyframeTrack(\.sway) {
                CubicKeyframe(0, duration: 0.18)
                CubicKeyframe(-46, duration: 0.20)
                CubicKeyframe(-30, duration: 0.17)
                LinearKeyframe(-30, duration: 0.35)
            }
            // Papa leans into the throw as it leaves, then settles.
            KeyframeTrack(\.lunge) {
                LinearKeyframe(0, duration: 0.08)
                CubicKeyframe(1, duration: 0.12)
                SpringKeyframe(0, duration: 0.7, spring: Spring(response: 0.35, dampingRatio: 0.5))
            }
            KeyframeTrack(\.shake) {
                LinearKeyframe(0, duration: 0.18)
                LinearKeyframe(-6, duration: 0.04)    // recoil as it leaves
                SpringKeyframe(0, duration: 0.68, spring: Spring(response: 0.2, dampingRatio: 0.3))
            }
            KeyframeTrack(\.flash) {
                LinearKeyframe(0, duration: 0.52)
                LinearKeyframe(1, duration: 0.03)
                LinearKeyframe(0, duration: 0.35)
            }
        }
    }

    // MARK: - The throw

    /// How far down the chappal travels before it is gone. The panel is made tall
    /// enough for this when a chappal nudge is shown (see NotchController.frame).
    static let throwTravel: CGFloat = 330
    /// Extra panel width either side for a chappal nudge, so the enlarged, tumbling
    /// chappal is not cut off at the panel edge. The block keeps its place on screen.
    static let throwSidePad: CGFloat = 260
    private var sidePad: CGFloat { model.nudge?.chappal == true ? Self.throwSidePad : 0 }

    /// Drawn above everything, in a strip that starts at the block's bottom edge and
    /// is clipped there, so the chappal appears from behind the block rather than over it.
    private func thrownChappal(_ pose: ThrowPose) -> some View {
        let topHeight = model.hasNotch ? model.notchHeight : 0
        let blockSpan = blockWidth + flare * 2
        let stripWidth = sidePad * 2 + blockSpan + NotchController.bubbleGap + bubbleWidth + NotchController.shadowPad
        let stripHeight = Self.throwTravel + 120
        return ZStack(alignment: .top) {
            Color.clear
            ChappalView()
                .rotation3DEffect(.degrees(pose.tumble), axis: (x: 1, y: 0.15, z: 0), perspective: 0.55)
                .rotationEffect(.degrees(pose.spin))
                .scaleEffect(1 + pose.fly * 4.2)
                .blur(radius: pose.fly * pose.fly * 6)
                .opacity(pose.opacity)
                .offset(x: sidePad + blockSpan / 2 - stripWidth / 2 + pose.sway,
                        y: -ChappalView.size.height + pose.fly * (Self.throwTravel + ChappalView.size.height))
        }
        .frame(width: stripWidth, height: stripHeight)
        .clipped()
        .offset(y: topHeight + bodyHeight)
        .allowsHitTesting(false)
    }

    // MARK: - Block with Papa

    private func block(_ pose: ThrowPose) -> some View {
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
                .scaleEffect(1 + pose.lunge * 0.08, anchor: .bottom)
                .rotationEffect(.degrees(pose.lunge * 6), anchor: .bottom)
                .padding(.bottom, 2)
                // Comes down out of the notch, retracts back up into it.
                .offset(x: pose.shake, y: expanded ? 0 : -(bodyHeight + 10))
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

    private func bubble(_ pose: ThrowPose) -> some View {
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
        .overlay(
            BubbleShape(cornerRadius: 22, tailY: 50)
                .stroke(Color(red: 0.9, green: 0.15, blue: 0.1), lineWidth: 3)
                .opacity(pose.flash)
        )
        .offset(x: pose.shake * 0.5)
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
