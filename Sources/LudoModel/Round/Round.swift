import Foundation

public struct Round: Equatable, Codable, Sendable {
    // MARK: - Initialized Properties
    public let id: String
    public let started: Date
    public let board: Board

    // MARK: - Round Progression
    public internal(set) var state: State
    public internal(set) var players: [Player]
    public internal(set) var tokens: [Token]
    public internal(set) var rankings: [PlayerID] = []
    public internal(set) var consecutiveSixes: Int = 0

    // MARK: - Results
    public internal(set) var log: Log = .init()
    public internal(set) var ended: Date?

    public enum State: Equatable, Codable, Sendable {
        case waitingForRoll(playerId: PlayerID)
        case waitingForTokenChoice(playerId: PlayerID, dieValue: Int)
        case roundComplete
    }
}
