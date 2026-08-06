import SwiftUI

enum CicadaBackgroundStyle: String, CaseIterable, Identifiable {
    case bamboo
    case sunrise
    case dawn
    case ink
    case jade

    static let storageKey = "cicadaBackgroundStyle"

    var id: String { rawValue }

    // New background artwork can be added per style without changing selection or persistence.
    var textureAssetName: String? {
        switch self {
        case .bamboo: "BambooLogoBackground"
        case .sunrise: "WallpaperBambooSunrise"
        case .dawn: "WallpaperAutumnEmber"
        case .ink: "WallpaperMoonLake"
        case .jade: "WallpaperLotusStorm"
        }
    }

    var showsBambooVeil: Bool { self == .bamboo }

    var baseColor: Color {
        switch self {
        case .bamboo: Color(red: 0.08, green: 0.25, blue: 0.17)
        case .sunrise: Color(red: 0.77, green: 0.76, blue: 0.56)
        case .dawn: Color(red: 0.48, green: 0.13, blue: 0.12)
        case .ink: Color(red: 0.06, green: 0.08, blue: 0.12)
        case .jade: Color(red: 0.04, green: 0.31, blue: 0.28)
        }
    }

    var accentColor: Color {
        switch self {
        case .bamboo: Color(red: 0.95, green: 0.86, blue: 0.38)
        case .sunrise: Color(red: 0.96, green: 0.72, blue: 0.25)
        case .dawn: Color(red: 1.0, green: 0.76, blue: 0.38)
        case .ink: Color(red: 0.59, green: 0.71, blue: 0.9)
        case .jade: Color(red: 0.78, green: 0.95, blue: 0.64)
        }
    }
}

enum CicadaStyle: String, CaseIterable, Identifiable {
    case red
    case purple
    case gold
    case orange
    case black

    static let storageKey = "cicadaStyleV2"

    var id: String { rawValue }

    // Future illustrated variants can supply an asset here while retaining the original toy drawing.
    var bodyTextureAssetName: String? { nil }

    // Current styles share one color between the original red head and the bead pair.
    var accentColor: Color {
        switch self {
        case .red: .red
        case .purple: Color(red: 0.30, green: 0.10, blue: 0.42)
        case .gold: Color(red: 0.95, green: 0.68, blue: 0.08)
        case .orange: Color(red: 0.95, green: 0.3, blue: 0.06)
        case .black: Color(red: 0.16, green: 0.17, blue: 0.19)
        }
    }

    var beadColor: Color { accentColor }
    var headColor: Color { accentColor }
}
