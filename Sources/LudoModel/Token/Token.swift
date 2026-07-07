import Foundation

public typealias TokenID = Int

public struct Token: Equatable, Codable, Sendable, Identifiable {
    public let id: TokenID
    public let playerID: PlayerID
    public internal(set) var stepsFromBase: Int

    public var isInBase: Bool { stepsFromBase == 0 }

    public enum CodingKeys: String, CodingKey {
        case id
        case playerID = "playerId"
        case stepsFromBase
    }

    public init(id: TokenID, playerID: PlayerID, stepsFromBase: Int = 0) {
        self.id = id
        self.playerID = playerID
        self.stepsFromBase = stepsFromBase
    }
}
