import SwiftUI

/// A vector-drawn Indian father. Everything is laid out on a 100x100 canvas
/// and scaled to `size`, so it looks crisp in the notch and in Settings.
struct PapaAvatarView: View {
    var config: AvatarConfig
    var expression: Expression = .neutral
    var size: CGFloat = 64
    var background: Color = Color(red: 0.16, green: 0.16, blue: 0.18)
    var animated: Bool = true

    private var skin: Color { SkinTones.color(config.skinTone) }
    private var skinShadow: Color { SkinTones.shadow(config.skinTone) }
    private var outfit: Color { OutfitColors.color(config.outfitColor) }

    var body: some View {
        ZStack {
            Circle().fill(background)
            OutfitView(style: config.outfit, color: outfit, skin: skin)
                .offset(y: 62)
            Rectangle().fill(skin).frame(width: 18, height: 22).offset(y: 60)
            Rectangle().fill(skinShadow.opacity(0.5)).frame(width: 18, height: 6).offset(y: 52)
            PapaHeadView(config: config, expression: expression, animated: animated)
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .scaleEffect(size / 100)
        .frame(width: size, height: size)
        .accessibilityLabel("Papa avatar")
    }
}

/// Papa peeking over a ledge with both hands, the way he appears in the notch.
/// Uses the user's picture when one is set, otherwise the drawing.
struct PeekingPapaView: View {
    var config: AvatarConfig
    var expression: Expression = .neutral
    /// Base picture (usually the neutral face).
    var image: NSImage?
    /// Picture for the current mood, cross-faded over `image` by `moodOpacity`.
    var moodImage: NSImage? = nil
    var moodOpacity: Double = 1
    var width: CGFloat
    var height: CGFloat
    var animated: Bool = true

    var body: some View {
        Group {
            if config.useImage, let image {
                ZStack {
                    picture(image)
                    if let moodImage, moodImage !== image {
                        picture(moodImage).opacity(moodOpacity)
                    }
                }
            } else {
                drawn
            }
        }
        .frame(width: width, height: height, alignment: .bottom)
        .clipped()
    }

    private func picture(_ img: NSImage) -> some View {
        Image(nsImage: img)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(height: height * config.imageZoom)
            .offset(y: config.imageOffsetY)
    }

    /// Canvas rows 0...86 are shown; 86 is the ledge the hands rest on.
    private var drawn: some View {
        let scale = height / 75
        return ZStack {
            PapaHeadView(config: config, expression: expression, animated: animated)
            HandsView(skin: SkinTones.color(config.skinTone), shadow: SkinTones.shadow(config.skinTone))
        }
        .frame(width: 100, height: 100)
        .frame(width: 100, height: 86, alignment: .top)
        .clipped()
        .scaleEffect(scale, anchor: .bottom)
        .frame(width: 100 * scale, height: 86 * scale, alignment: .bottom)
    }
}

/// Just the head: ears, face, hair, eyes, glasses, mustache. Drawn on a 100x100 canvas.
struct PapaHeadView: View {
    var config: AvatarConfig
    var expression: Expression = .neutral
    var animated: Bool = true

    @State private var blink = false
    @State private var blinkTask: Task<Void, Never>?

    private var skin: Color { SkinTones.color(config.skinTone) }
    private var skinShadow: Color { SkinTones.shadow(config.skinTone) }
    private var hair: Color { config.hairColor.color }

    var body: some View {
        ZStack {
            // Ears
            Ellipse().fill(skin).frame(width: 10, height: 13).offset(x: -27, y: 2)
            Ellipse().fill(skin).frame(width: 10, height: 13).offset(x: 27, y: 2)

            // Head
            Ellipse()
                .fill(skin)
                .frame(width: 54, height: 62)
                .offset(y: -2)

            // Hair
            HairShape(style: config.hair)
                .fill(hair)
                .frame(width: 100, height: 100)

            // Tilak
            if config.tilak {
                Capsule()
                    .fill(Color(red: 0.85, green: 0.15, blue: 0.10))
                    .frame(width: 3, height: 9)
                    .offset(y: -18)
            }

            // Eyebrows
            Capsule().fill(hair)
                .frame(width: 13, height: 3.6)
                .rotationEffect(.degrees(leftBrowAngle))
                .offset(x: -11, y: browY)
            Capsule().fill(hair)
                .frame(width: 13, height: 3.6)
                .rotationEffect(.degrees(-leftBrowAngle))
                .offset(x: 11, y: browY)

            // Eyes
            eye.offset(x: -10.5, y: -1)
            eye.offset(x: 10.5, y: -1)

            // Glasses
            GlassesView(style: config.glasses)

            // Nose
            NoseShape()
                .stroke(skinShadow, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .frame(width: 100, height: 100)

            // Mouth (drawn before the mustache so it peeks out beneath)
            MouthShape(expression: expression)
                .stroke(Color(red: 0.45, green: 0.18, blue: 0.16), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 100, height: 100)

            // Mustache
            MustacheShape(style: config.mustache)
                .fill(hair)
                .frame(width: 100, height: 100)
        }
        .frame(width: 100, height: 100)
        .onAppear { if animated { startBlinking() } }
        .onDisappear { blinkTask?.cancel() }
    }

    private var eye: some View {
        ZStack {
            Ellipse().fill(.white).frame(width: 11, height: 8)
            Circle().fill(Color(red: 0.13, green: 0.09, blue: 0.07)).frame(width: 4.6, height: 4.6).offset(x: 0.6, y: 0.3)
            Circle().fill(.white).frame(width: 1.4, height: 1.4).offset(x: 1.6, y: -0.9)
        }
        .scaleEffect(y: blink ? 0.08 : 1, anchor: .center)
    }

    private var leftBrowAngle: Double {
        switch expression {
        case .stern: return 14
        case .worried: return -12
        case .happy, .proud: return -4
        case .neutral: return 2
        }
    }

    private var browY: CGFloat {
        switch expression {
        case .stern: return -8
        case .worried: return -12
        case .happy, .proud: return -11
        case .neutral: return -10
        }
    }

    private func startBlinking() {
        blinkTask?.cancel()
        blinkTask = Task { @MainActor in
            while !Task.isCancelled {
                let wait = UInt64.random(in: 2_400...5_200)
                try? await Task.sleep(nanoseconds: wait * 1_000_000)
                if Task.isCancelled { return }
                withAnimation(.easeIn(duration: 0.07)) { blink = true }
                try? await Task.sleep(nanoseconds: 110_000_000)
                withAnimation(.easeOut(duration: 0.09)) { blink = false }
            }
        }
    }
}

/// Two hands gripping the ledge (canvas y = 86), fingers curling over the chin.
private struct HandsView: View {
    var skin: Color
    var shadow: Color

    var body: some View {
        ZStack {
            hand.offset(x: -21, y: 31)
            hand.offset(x: 21, y: 31)
        }
        .frame(width: 100, height: 100)
    }

    private var hand: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                .fill(skin)
                .frame(width: 18, height: 12)
                .offset(y: 2)
            HStack(spacing: 1.0) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(skin)
                        .overlay(Capsule().strokeBorder(shadow.opacity(0.35), lineWidth: 0.5))
                        .frame(width: 3.6, height: i == 0 || i == 3 ? 8 : 9.5)
                }
            }
            .offset(y: -6)
        }
        .frame(width: 20, height: 16)
    }
}

// MARK: - Parts

private struct OutfitView: View {
    var style: OutfitStyle
    var color: Color
    var skin: Color

    var body: some View {
        ZStack {
            // Shoulders
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(color)
                .frame(width: 84, height: 60)
                .offset(y: 22)

            switch style {
            case .kurta:
                // Band collar with a small placket
                Capsule()
                    .stroke(color.opacity(0.0), lineWidth: 0)
                RoundedRectangle(cornerRadius: 3)
                    .fill(color.darker(0.85))
                    .frame(width: 26, height: 6)
                    .offset(y: 8)
                Rectangle()
                    .fill(color.darker(0.85))
                    .frame(width: 1.4, height: 16)
                    .offset(y: 20)
                Circle().fill(color.darker(0.7)).frame(width: 2, height: 2).offset(y: 16)
                Circle().fill(color.darker(0.7)).frame(width: 2, height: 2).offset(y: 22)
            case .shirt:
                CollarShape()
                    .fill(color.lighter(1.12))
                    .frame(width: 100, height: 100)
                    .offset(y: -50)
                Rectangle().fill(color.darker(0.8)).frame(width: 1.2, height: 18).offset(y: 20)
            case .sweaterVest:
                // Shirt collar peeking above the vest
                CollarShape()
                    .fill(Color(red: 0.93, green: 0.93, blue: 0.95))
                    .frame(width: 100, height: 100)
                    .offset(y: -50)
                VNeckShape()
                    .fill(color)
                    .frame(width: 100, height: 100)
                    .offset(y: -50)
            case .safari:
                CollarShape()
                    .fill(color.lighter(1.08))
                    .frame(width: 100, height: 100)
                    .offset(y: -50)
                // Chest pockets
                RoundedRectangle(cornerRadius: 1.5).stroke(color.darker(0.7), lineWidth: 1)
                    .frame(width: 10, height: 8).offset(x: -18, y: 26)
                RoundedRectangle(cornerRadius: 1.5).stroke(color.darker(0.7), lineWidth: 1)
                    .frame(width: 10, height: 8).offset(x: 18, y: 26)
            }
        }
    }
}

private struct CollarShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Two collar wings meeting at the neck (relative to a 100x100 box
        // whose y=50 line is the shoulder top).
        var p = Path()
        p.move(to: CGPoint(x: 41, y: 52))
        p.addLine(to: CGPoint(x: 50, y: 66))
        p.addLine(to: CGPoint(x: 33, y: 64))
        p.closeSubpath()
        p.move(to: CGPoint(x: 59, y: 52))
        p.addLine(to: CGPoint(x: 50, y: 66))
        p.addLine(to: CGPoint(x: 67, y: 64))
        p.closeSubpath()
        return p
    }
}

private struct VNeckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 8, y: 60))
        p.addLine(to: CGPoint(x: 36, y: 60))
        p.addLine(to: CGPoint(x: 50, y: 76))
        p.addLine(to: CGPoint(x: 64, y: 60))
        p.addLine(to: CGPoint(x: 92, y: 60))
        p.addLine(to: CGPoint(x: 92, y: 110))
        p.addLine(to: CGPoint(x: 8, y: 110))
        p.closeSubpath()
        return p
    }
}

private struct HairShape: Shape {
    var style: HairStyle

    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch style {
        case .sidePart:
            p.move(to: CGPoint(x: 23, y: 38))
            p.addCurve(to: CGPoint(x: 50, y: 15), control1: CGPoint(x: 23, y: 22), control2: CGPoint(x: 34, y: 15))
            p.addCurve(to: CGPoint(x: 77, y: 38), control1: CGPoint(x: 66, y: 15), control2: CGPoint(x: 77, y: 22))
            // Bottom edge: high on the parted side, fringe dips on the other
            p.addCurve(to: CGPoint(x: 62, y: 27), control1: CGPoint(x: 75, y: 30), control2: CGPoint(x: 69, y: 26))
            p.addCurve(to: CGPoint(x: 40, y: 31), control1: CGPoint(x: 56, y: 28), control2: CGPoint(x: 48, y: 33))
            p.addCurve(to: CGPoint(x: 23, y: 38), control1: CGPoint(x: 33, y: 29), control2: CGPoint(x: 26, y: 33))
            p.closeSubpath()
            // Sideburns
            p.addRoundedRect(in: CGRect(x: 22.5, y: 34, width: 4, height: 12), cornerSize: CGSize(width: 2, height: 2))
            p.addRoundedRect(in: CGRect(x: 73.5, y: 34, width: 4, height: 12), cornerSize: CGSize(width: 2, height: 2))
        case .combedBack:
            p.move(to: CGPoint(x: 23, y: 36))
            p.addCurve(to: CGPoint(x: 50, y: 13), control1: CGPoint(x: 23, y: 20), control2: CGPoint(x: 34, y: 13))
            p.addCurve(to: CGPoint(x: 77, y: 36), control1: CGPoint(x: 66, y: 13), control2: CGPoint(x: 77, y: 20))
            p.addCurve(to: CGPoint(x: 50, y: 25), control1: CGPoint(x: 70, y: 27), control2: CGPoint(x: 60, y: 25))
            p.addCurve(to: CGPoint(x: 23, y: 36), control1: CGPoint(x: 40, y: 25), control2: CGPoint(x: 30, y: 27))
            p.closeSubpath()
            p.addRoundedRect(in: CGRect(x: 22.5, y: 32, width: 4, height: 13), cornerSize: CGSize(width: 2, height: 2))
            p.addRoundedRect(in: CGRect(x: 73.5, y: 32, width: 4, height: 13), cornerSize: CGSize(width: 2, height: 2))
        case .receding:
            // Thin top strip pushed back, fuller on the sides
            p.move(to: CGPoint(x: 30, y: 28))
            p.addCurve(to: CGPoint(x: 70, y: 28), control1: CGPoint(x: 38, y: 17), control2: CGPoint(x: 62, y: 17))
            p.addCurve(to: CGPoint(x: 30, y: 28), control1: CGPoint(x: 60, y: 23), control2: CGPoint(x: 40, y: 23))
            p.closeSubpath()
            p.addPath(sidePatch(x: 22.5))
            p.addPath(sidePatch(x: 70.5))
        case .bald:
            p.addPath(sidePatch(x: 22.5))
            p.addPath(sidePatch(x: 70.5))
        }
        return p
    }

    private func sidePatch(x: CGFloat) -> Path {
        Path(roundedRect: CGRect(x: x, y: 28, width: 7, height: 20), cornerRadius: 3.5)
    }
}

private struct GlassesView: View {
    var style: GlassesStyle
    private let frameColor = Color(red: 0.78, green: 0.62, blue: 0.20)

    var body: some View {
        switch style {
        case .none:
            EmptyView()
        case .rectangular:
            ZStack {
                RoundedRectangle(cornerRadius: 3).stroke(frameColor, lineWidth: 1.6).frame(width: 16, height: 12).offset(x: -10.5, y: -1)
                RoundedRectangle(cornerRadius: 3).stroke(frameColor, lineWidth: 1.6).frame(width: 16, height: 12).offset(x: 10.5, y: -1)
                Rectangle().fill(frameColor).frame(width: 5, height: 1.4).offset(y: -3)
                Rectangle().fill(frameColor).frame(width: 6, height: 1.2).offset(x: -21.5, y: -3)
                Rectangle().fill(frameColor).frame(width: 6, height: 1.2).offset(x: 21.5, y: -3)
            }
        case .round:
            ZStack {
                Circle().stroke(Color.black.opacity(0.85), lineWidth: 1.6).frame(width: 15, height: 15).offset(x: -10.5, y: -1)
                Circle().stroke(Color.black.opacity(0.85), lineWidth: 1.6).frame(width: 15, height: 15).offset(x: 10.5, y: -1)
                Rectangle().fill(Color.black.opacity(0.85)).frame(width: 6, height: 1.4).offset(y: -3)
                Rectangle().fill(Color.black.opacity(0.85)).frame(width: 6, height: 1.2).offset(x: -21, y: -3)
                Rectangle().fill(Color.black.opacity(0.85)).frame(width: 6, height: 1.2).offset(x: 21, y: -3)
            }
        case .halfRim:
            ZStack {
                HalfRimShape().stroke(frameColor, lineWidth: 1.8).frame(width: 16, height: 12).offset(x: -10.5, y: -1)
                HalfRimShape().stroke(frameColor, lineWidth: 1.8).frame(width: 16, height: 12).offset(x: 10.5, y: -1)
                Rectangle().fill(frameColor).frame(width: 5, height: 1.4).offset(y: -6)
                Rectangle().fill(frameColor).frame(width: 6, height: 1.2).offset(x: -21.5, y: -6)
                Rectangle().fill(frameColor).frame(width: 6, height: 1.2).offset(x: 21.5, y: -6)
            }
        }
    }
}

private struct HalfRimShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 2))
        p.addQuadCurve(to: CGPoint(x: rect.minX + 2, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + 2), control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

private struct NoseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 50, y: 44))
        p.addCurve(to: CGPoint(x: 46.5, y: 55), control1: CGPoint(x: 49, y: 48), control2: CGPoint(x: 46, y: 51))
        p.addQuadCurve(to: CGPoint(x: 52.5, y: 55.5), control: CGPoint(x: 49.5, y: 58))
        return p
    }
}

private struct MouthShape: Shape {
    var expression: Expression

    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch expression {
        case .happy, .proud:
            p.move(to: CGPoint(x: 43, y: 66))
            p.addQuadCurve(to: CGPoint(x: 57, y: 66), control: CGPoint(x: 50, y: 73))
        case .stern:
            p.move(to: CGPoint(x: 44.5, y: 69))
            p.addQuadCurve(to: CGPoint(x: 55.5, y: 69), control: CGPoint(x: 50, y: 65.5))
        case .worried:
            p.move(to: CGPoint(x: 45.5, y: 68.5))
            p.addQuadCurve(to: CGPoint(x: 54.5, y: 68.5), control: CGPoint(x: 50, y: 66.5))
        case .neutral:
            p.move(to: CGPoint(x: 45, y: 67.5))
            p.addQuadCurve(to: CGPoint(x: 55, y: 67.5), control: CGPoint(x: 50, y: 69.5))
        }
        return p
    }
}

private struct MustacheShape: Shape {
    var style: MustacheStyle

    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch style {
        case .none:
            return p
        case .classic:
            p.move(to: CGPoint(x: 50, y: 58))
            p.addCurve(to: CGPoint(x: 35, y: 61.5), control1: CGPoint(x: 44, y: 55.5), control2: CGPoint(x: 37, y: 57))
            p.addCurve(to: CGPoint(x: 50, y: 62.5), control1: CGPoint(x: 38, y: 66), control2: CGPoint(x: 46, y: 66))
            p.addCurve(to: CGPoint(x: 65, y: 61.5), control1: CGPoint(x: 54, y: 66), control2: CGPoint(x: 62, y: 66))
            p.addCurve(to: CGPoint(x: 50, y: 58), control1: CGPoint(x: 63, y: 57), control2: CGPoint(x: 56, y: 55.5))
            p.closeSubpath()
        case .walrus:
            p.move(to: CGPoint(x: 50, y: 57))
            p.addCurve(to: CGPoint(x: 31, y: 63), control1: CGPoint(x: 42, y: 54), control2: CGPoint(x: 33, y: 57))
            p.addCurve(to: CGPoint(x: 50, y: 63), control1: CGPoint(x: 35, y: 70), control2: CGPoint(x: 46, y: 68))
            p.addCurve(to: CGPoint(x: 69, y: 63), control1: CGPoint(x: 54, y: 68), control2: CGPoint(x: 65, y: 70))
            p.addCurve(to: CGPoint(x: 50, y: 57), control1: CGPoint(x: 67, y: 57), control2: CGPoint(x: 58, y: 54))
            p.closeSubpath()
        case .pencil:
            p.move(to: CGPoint(x: 50, y: 59))
            p.addCurve(to: CGPoint(x: 38, y: 60.5), control1: CGPoint(x: 46, y: 58), control2: CGPoint(x: 41, y: 58.5))
            p.addCurve(to: CGPoint(x: 50, y: 61.5), control1: CGPoint(x: 41, y: 62.5), control2: CGPoint(x: 47, y: 62.5))
            p.addCurve(to: CGPoint(x: 62, y: 60.5), control1: CGPoint(x: 53, y: 62.5), control2: CGPoint(x: 59, y: 62.5))
            p.addCurve(to: CGPoint(x: 50, y: 59), control1: CGPoint(x: 59, y: 58.5), control2: CGPoint(x: 54, y: 58))
            p.closeSubpath()
        }
        return p
    }
}

extension Color {
    func darker(_ factor: Double) -> Color {
        let ns = NSColor(self).usingColorSpace(.deviceRGB) ?? .gray
        return Color(red: Double(ns.redComponent) * factor, green: Double(ns.greenComponent) * factor, blue: Double(ns.blueComponent) * factor)
    }

    func lighter(_ factor: Double) -> Color {
        let ns = NSColor(self).usingColorSpace(.deviceRGB) ?? .gray
        return Color(red: min(1, Double(ns.redComponent) * factor), green: min(1, Double(ns.greenComponent) * factor), blue: min(1, Double(ns.blueComponent) * factor))
    }
}
