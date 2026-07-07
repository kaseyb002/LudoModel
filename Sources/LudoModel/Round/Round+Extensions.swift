import Foundation

extension Round {
    public var currentPlayerID: PlayerID? {
        switch state {
        case .waitingForRoll(let playerID):
            return playerID
        case .waitingForTokenChoice(let playerID, _):
            return playerID
        case .roundComplete:
            return nil
        }
    }

    public var currentPlayer: Player? {
        guard let currentPlayerID else { return nil }
        return players.first(where: { $0.id == currentPlayerID })
    }

    public func playerIndex(for playerID: PlayerID) -> Int? {
        players.firstIndex(where: { $0.id == playerID })
    }

    public func tokens(for playerID: PlayerID) -> [Token] {
        tokens.filter { $0.playerID == playerID }
    }

    public func tokensInBase(for playerID: PlayerID) -> [Token] {
        tokens(for: playerID).filter(\.isInBase)
    }

    public func tokensOnTrack(for playerID: PlayerID) -> [Token] {
        tokens(for: playerID).filter { board.isOnMainTrack($0.stepsFromBase) }
    }

    public func tokensInHomeColumn(for playerID: PlayerID) -> [Token] {
        tokens(for: playerID).filter { board.isInHomeColumn($0.stepsFromBase) }
    }

    public func tokensFinished(for playerID: PlayerID) -> [Token] {
        tokens(for: playerID).filter { board.isFinished($0.stepsFromBase) }
    }

    public func allTokensFinished(for playerID: PlayerID) -> Bool {
        tokens(for: playerID).allSatisfy { board.isFinished($0.stepsFromBase) }
    }

    public func progress(for playerID: PlayerID) -> Double {
        let playerTokens: [Token] = tokens(for: playerID)
        let totalSteps: Int = playerTokens.reduce(0) { $0 + $1.stepsFromBase }
        let maxSteps: Int = 4 * board.finishedStep
        return Double(totalSteps) / Double(maxSteps)
    }

    public var logValue: String {
        var lines: [String] = []
        lines.append("State: \(stateDescription)")
        lines.append("Rankings: \(rankings)")
        for player in players {
            let playerTokens: [Token] = tokens(for: player.id)
            let tokenSteps: String = playerTokens.map { "T\($0.id):\($0.stepsFromBase)" }.joined(separator: ", ")
            let finished: Bool = allTokensFinished(for: player.id)
            lines.append("\(player.name) (\(player.color.displayableName)): [\(tokenSteps)] finished=\(finished)")
        }
        return lines.joined(separator: "\n")
    }

    private var stateDescription: String {
        switch state {
        case .waitingForRoll(let playerID):
            "Waiting for \(players.first(where: { $0.id == playerID })?.name ?? playerID) to roll"
        case .waitingForTokenChoice(let playerID, let dieValue):
            "Waiting for \(players.first(where: { $0.id == playerID })?.name ?? playerID) to choose token (rolled \(dieValue))"
        case .roundComplete:
            "Round complete. Rankings: \(rankings)"
        }
    }
}
