import Foundation

public enum PlayerColor: String, CaseIterable, Equatable, Codable, Sendable {
    case red
    case blue
    case green
    case yellow
    case purple
    case orange

    public var displayableName: String {
        switch self {
        case .red: "Red"
        case .blue: "Blue"
        case .green: "Green"
        case .yellow: "Yellow"
        case .purple: "Purple"
        case .orange: "Orange"
        }
    }
}
