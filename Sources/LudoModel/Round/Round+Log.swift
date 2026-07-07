import Foundation

extension Round {
    public struct Log: Equatable, Codable, Sendable {
        public var actions: [PlayerAction] = []

        private static let maxActions: Int = 100

        public struct PlayerAction: Equatable, Codable, Sendable {
            public let playerID: PlayerID
            public let decision: Decision
            public let timestamp: Date

            public enum Decision: Equatable, Codable, Sendable {
                case rolled(dieValue: Int)
                case movedToken(tokenId: TokenID, stepsFromBase: Int)
                case movedOutOfBase(tokenId: TokenID)
                case capturedOpponent(tokenId: TokenID, capturedTokenId: TokenID)
                case enteredHome(tokenId: TokenID)
                case noLegalMove
                case threeConsecutiveSixes
            }

            public enum CodingKeys: String, CodingKey {
                case playerID = "playerId"
                case decision
                case timestamp
            }

            public init(
                playerID: PlayerID,
                decision: Decision,
                timestamp: Date = .init()
            ) {
                self.playerID = playerID
                self.decision = decision
                self.timestamp = timestamp
            }
        }

        public init(actions: [PlayerAction] = []) {
            self.actions = actions
        }

        public mutating func addAction(_ action: PlayerAction) {
            actions.append(action)
            if actions.count > Self.maxActions {
                actions.removeFirst(actions.count - Self.maxActions)
            }
        }
    }
}
