import SwiftUI

enum MustacheStyle: String, Codable, CaseIterable, Identifiable {
    case classic, walrus, pencil, none
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .walrus: return "Walrus"
        case .pencil: return "Pencil"
        case .none: return "Clean shaven"
        }
    }
}

enum GlassesStyle: String, Codable, CaseIterable, Identifiable {
    case none, rectangular, round, halfRim
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .none: return "None"
        case .rectangular: return "Rectangular"
        case .round: return "Round"
        case .halfRim: return "Half rim"
        }
    }
}

enum HairStyle: String, Codable, CaseIterable, Identifiable {
    case sidePart, combedBack, receding, bald
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .sidePart: return "Side part"
        case .combedBack: return "Combed back"
        case .receding: return "Receding"
        case .bald: return "Bald"
        }
    }
}

enum HairColor: String, Codable, CaseIterable, Identifiable {
    case black, saltPepper, grey, white
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .black: return "Black"
        case .saltPepper: return "Salt & pepper"
        case .grey: return "Grey"
        case .white: return "White"
        }
    }
    var color: Color {
        switch self {
        case .black: return Color(red: 0.12, green: 0.10, blue: 0.09)
        case .saltPepper: return Color(red: 0.36, green: 0.35, blue: 0.35)
        case .grey: return Color(red: 0.62, green: 0.62, blue: 0.63)
        case .white: return Color(red: 0.90, green: 0.90, blue: 0.90)
        }
    }
}

enum OutfitStyle: String, Codable, CaseIterable, Identifiable {
    case kurta, shirt, sweaterVest, safari
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .kurta: return "Kurta"
        case .shirt: return "Shirt"
        case .sweaterVest: return "Sweater vest"
        case .safari: return "Safari suit"
        }
    }
}

struct AvatarConfig: Codable, Hashable {
    var skinTone: Int = 2          // index into SkinTones.all
    var mustache: MustacheStyle = .classic
    var glasses: GlassesStyle = .rectangular
    var hair: HairStyle = .sidePart
    var hairColor: HairColor = .saltPepper
    var outfit: OutfitStyle = .kurta
    var outfitColor: Int = 1       // index into OutfitColors.all
    var tilak: Bool = false

    /// Show a picture (the bundled Papa or your own, see AvatarImageStore) instead of the drawing.
    var useImage: Bool = true
    /// Scale of the picture relative to the notch block height.
    var imageZoom: Double = 1.0
    /// Vertical nudge of the picture in points; positive moves it down (peeks less).
    var imageOffsetY: Double = 0

    init() {}

    init(skinTone: Int, mustache: MustacheStyle, glasses: GlassesStyle, hair: HairStyle, hairColor: HairColor,
         outfit: OutfitStyle, outfitColor: Int, tilak: Bool) {
        self.skinTone = skinTone; self.mustache = mustache; self.glasses = glasses; self.hair = hair
        self.hairColor = hairColor; self.outfit = outfit; self.outfitColor = outfitColor; self.tilak = tilak
    }

    enum CodingKeys: String, CodingKey {
        case skinTone, mustache, glasses, hair, hairColor, outfit, outfitColor, tilak, imageZoom, imageOffsetY
        // Stored under a new key on purpose: builds before the bundled Papa existed
        // saved `useImage: false`, and that should not stick once he ships in the box.
        case useImage = "usePicture"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AvatarConfig()
        skinTone = try c.decodeIfPresent(Int.self, forKey: .skinTone) ?? d.skinTone
        mustache = try c.decodeIfPresent(MustacheStyle.self, forKey: .mustache) ?? d.mustache
        glasses = try c.decodeIfPresent(GlassesStyle.self, forKey: .glasses) ?? d.glasses
        hair = try c.decodeIfPresent(HairStyle.self, forKey: .hair) ?? d.hair
        hairColor = try c.decodeIfPresent(HairColor.self, forKey: .hairColor) ?? d.hairColor
        outfit = try c.decodeIfPresent(OutfitStyle.self, forKey: .outfit) ?? d.outfit
        outfitColor = try c.decodeIfPresent(Int.self, forKey: .outfitColor) ?? d.outfitColor
        tilak = try c.decodeIfPresent(Bool.self, forKey: .tilak) ?? d.tilak
        useImage = try c.decodeIfPresent(Bool.self, forKey: .useImage) ?? d.useImage
        imageZoom = try c.decodeIfPresent(Double.self, forKey: .imageZoom) ?? d.imageZoom
        imageOffsetY = try c.decodeIfPresent(Double.self, forKey: .imageOffsetY) ?? d.imageOffsetY
    }
}

enum SkinTones {
    static let all: [Color] = [
        Color(red: 0.96, green: 0.80, blue: 0.62),
        Color(red: 0.89, green: 0.68, blue: 0.47),
        Color(red: 0.78, green: 0.55, blue: 0.34),
        Color(red: 0.62, green: 0.40, blue: 0.22),
        Color(red: 0.42, green: 0.26, blue: 0.14),
    ]
    static func color(_ index: Int) -> Color { all[max(0, min(index, all.count - 1))] }
    static func shadow(_ index: Int) -> Color { color(index).opacity(0.55).blendDarker() }
}

enum OutfitColors {
    static let all: [(name: String, color: Color)] = [
        ("Cream", Color(red: 0.95, green: 0.91, blue: 0.82)),
        ("Maroon", Color(red: 0.50, green: 0.13, blue: 0.18)),
        ("Navy", Color(red: 0.13, green: 0.23, blue: 0.38)),
        ("Olive", Color(red: 0.34, green: 0.42, blue: 0.19)),
        ("Saffron", Color(red: 0.91, green: 0.55, blue: 0.18)),
        ("Teal", Color(red: 0.12, green: 0.44, blue: 0.47)),
        ("Sky", Color(red: 0.56, green: 0.72, blue: 0.86)),
    ]
    static func color(_ index: Int) -> Color { all[max(0, min(index, all.count - 1))].color }
}

private extension Color {
    func blendDarker() -> Color {
        let ns = NSColor(self).usingColorSpace(.deviceRGB) ?? .brown
        return Color(red: Double(ns.redComponent) * 0.7, green: Double(ns.greenComponent) * 0.7, blue: Double(ns.blueComponent) * 0.7)
    }
}
