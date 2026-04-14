import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case defaultTheme = "default"
    case ocean = "ocean"
    case sunset = "sunset"
    case lavender = "lavender"
    case monochrome = "monochrome"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .defaultTheme: return "Default"
        case .ocean: return "Ocean"
        case .sunset: return "Sunset"
        case .lavender: return "Lavender"
        case .monochrome: return "Monochrome"
        }
    }

    var completedColor: Color {
        switch self {
        case .defaultTheme: return .green
        case .ocean: return Color(red: 0.0, green: 0.6, blue: 0.85)
        case .sunset: return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .lavender: return Color(red: 0.6, green: 0.4, blue: 0.9)
        case .monochrome: return .black
        }
    }

    var failedColor: Color {
        switch self {
        case .defaultTheme: return .red
        case .ocean: return Color(red: 0.1, green: 0.2, blue: 0.5)
        case .sunset: return Color(red: 0.8, green: 0.2, blue: 0.1)
        case .lavender: return Color(red: 0.4, green: 0.2, blue: 0.5)
        case .monochrome: return Color(white: 0.35)
        }
    }

    var notCompletedColor: Color {
        switch self {
        case .defaultTheme: return .gray.opacity(0.3)
        case .ocean: return Color(red: 0.7, green: 0.85, blue: 0.95)
        case .sunset: return Color(red: 1.0, green: 0.9, blue: 0.75)
        case .lavender: return Color(red: 0.85, green: 0.8, blue: 0.95)
        case .monochrome: return Color(white: 0.85)
        }
    }

    var accentColor: Color {
        switch self {
        case .defaultTheme: return .blue
        case .ocean: return Color(red: 0.0, green: 0.45, blue: 0.75)
        case .sunset: return Color(red: 0.95, green: 0.45, blue: 0.1)
        case .lavender: return Color(red: 0.5, green: 0.3, blue: 0.8)
        case .monochrome: return .black
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
