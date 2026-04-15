import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case defaultTheme = "default"
    case ocean = "ocean"
    case sunset = "sunset"
    case lavender = "lavender"
    case monochrome = "monochrome"
    case dynamic = "dynamic"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .defaultTheme: return "Default"
        case .ocean: return "Ocean"
        case .sunset: return "Sunset"
        case .lavender: return "Lavender"
        case .monochrome: return "Monochrome"
        case .dynamic: return "Dynamic"
        }
    }

    /// SF Symbol for the theme picker (only used by Dynamic)
    var iconName: String? {
        switch self {
        case .dynamic: return "clock.arrow.2.circlepath"
        default: return nil
        }
    }

    var completedColor: Color {
        switch self {
        case .defaultTheme: return .green
        case .ocean: return Color(red: 0.0, green: 0.6, blue: 0.85)
        case .sunset: return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .lavender: return Color(red: 0.6, green: 0.4, blue: 0.9)
        case .monochrome: return .black
        case .dynamic: return DynamicPalette.current.completed
        }
    }

    var failedColor: Color {
        switch self {
        case .defaultTheme: return .red
        case .ocean: return Color(red: 0.1, green: 0.2, blue: 0.5)
        case .sunset: return Color(red: 0.8, green: 0.2, blue: 0.1)
        case .lavender: return Color(red: 0.4, green: 0.2, blue: 0.5)
        case .monochrome: return Color(white: 0.55)
        case .dynamic: return DynamicPalette.current.failed
        }
    }

    var notCompletedColor: Color {
        switch self {
        case .defaultTheme: return .gray.opacity(0.3)
        case .ocean: return Color(red: 0.7, green: 0.85, blue: 0.95)
        case .sunset: return Color(red: 1.0, green: 0.9, blue: 0.75)
        case .lavender: return Color(red: 0.85, green: 0.8, blue: 0.95)
        case .monochrome: return Color(white: 0.85)
        case .dynamic: return DynamicPalette.current.notCompleted
        }
    }

    var accentColor: Color {
        switch self {
        case .defaultTheme: return .blue
        case .ocean: return Color(red: 0.0, green: 0.45, blue: 0.75)
        case .sunset: return Color(red: 0.95, green: 0.45, blue: 0.1)
        case .lavender: return Color(red: 0.5, green: 0.3, blue: 0.8)
        case .monochrome: return .black
        case .dynamic: return DynamicPalette.current.accent
        }
    }

    /// Preview colors for the theme picker: [completed, failed, notCompleted]
    var previewColors: [Color] {
        [completedColor, failedColor, notCompletedColor]
    }

    static func from(rawValue: String) -> AppTheme {
        AppTheme(rawValue: rawValue) ?? .defaultTheme
    }
}

// MARK: - Dynamic Theme (Time of Day)

/// Resolves colors based on the current hour of the day.
/// - Morning  (6am-12pm):  warm amber/coral tones — energizing start
/// - Afternoon (12pm-6pm): bright teal/blue tones — productive focus
/// - Evening  (6pm-10pm):  muted purple/mauve tones — winding down
/// - Night    (10pm-6am):  deep indigo/slate tones — restful dark
private struct DynamicPalette {

    let completed: Color
    let failed: Color
    let notCompleted: Color
    let accent: Color

    // MARK: - Time Period Detection

    static var current: DynamicPalette {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:   return .morning
        case 12..<18:  return .afternoon
        case 18..<22:  return .evening
        default:       return .night   // 22-23, 0-5
        }
    }

    // MARK: - Morning (6am - 12pm)
    // Warm, energizing palette: amber completed, coral failed, soft peach empty
    static let morning = DynamicPalette(
        completed:    Color(red: 0.95, green: 0.65, blue: 0.15),  // warm amber
        failed:       Color(red: 0.85, green: 0.30, blue: 0.25),  // coral red
        notCompleted: Color(red: 1.00, green: 0.90, blue: 0.75),  // soft peach
        accent:       Color(red: 0.90, green: 0.50, blue: 0.10)   // burnt orange
    )

    // MARK: - Afternoon (12pm - 6pm)
    // Bright, productive palette: teal completed, slate-blue failed, light cyan empty
    static let afternoon = DynamicPalette(
        completed:    Color(red: 0.10, green: 0.70, blue: 0.65),  // teal green
        failed:       Color(red: 0.30, green: 0.30, blue: 0.55),  // slate blue
        notCompleted: Color(red: 0.80, green: 0.92, blue: 0.92),  // pale cyan
        accent:       Color(red: 0.05, green: 0.55, blue: 0.60)   // deep teal
    )

    // MARK: - Evening (6pm - 10pm)
    // Calm, winding-down palette: soft lavender completed, dusty rose failed, light mauve empty
    static let evening = DynamicPalette(
        completed:    Color(red: 0.60, green: 0.50, blue: 0.80),  // soft purple
        failed:       Color(red: 0.65, green: 0.30, blue: 0.40),  // dusty rose
        notCompleted: Color(red: 0.85, green: 0.80, blue: 0.90),  // light mauve
        accent:       Color(red: 0.50, green: 0.35, blue: 0.70)   // medium purple
    )

    // MARK: - Night (10pm - 6am)
    // Deep, restful palette: muted blue-green completed, dark burgundy failed, charcoal empty
    static let night = DynamicPalette(
        completed:    Color(red: 0.25, green: 0.55, blue: 0.60),  // muted teal
        failed:       Color(red: 0.55, green: 0.20, blue: 0.25),  // dark burgundy
        notCompleted: Color(red: 0.25, green: 0.25, blue: 0.30),  // charcoal
        accent:       Color(red: 0.30, green: 0.45, blue: 0.60)   // steel blue
    )
}
