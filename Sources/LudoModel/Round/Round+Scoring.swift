import Foundation

extension Round {
    public var isGameComplete: Bool {
        if case .roundComplete = state {
            return true
        }
        return false
    }

    public var winner: Player? {
        guard let winnerID: PlayerID = rankings.first else { return nil }
        return players.first(where: { $0.id == winnerID })
    }

    public var standings: [(player: Player, finishedTokens: Int, totalProgress: Int)] {
        players.map { player in
            let playerTokens: [Token] = tokens(for: player.id)
            let finishedCount: Int = playerTokens.filter { board.isFinished($0.stepsFromBase) }.count
            let totalSteps: Int = playerTokens.reduce(0) { $0 + $1.stepsFromBase }
            return (player: player, finishedTokens: finishedCount, totalProgress: totalSteps)
        }.sorted { lhs, rhs in
            if lhs.finishedTokens != rhs.finishedTokens {
                return lhs.finishedTokens > rhs.finishedTokens
            }
            return lhs.totalProgress > rhs.totalProgress
        }
    }
}
