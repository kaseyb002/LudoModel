import Foundation

extension Round {
    public init(
        id: String = UUID().uuidString,
        started: Date = .init(),
        players: [Player]
    ) throws {
        guard players.count >= 2 else {
            throw LudoError.notEnoughPlayers
        }
        guard players.count <= 6 else {
            throw LudoError.tooManyPlayers
        }
        let colors: Set<PlayerColor> = Set(players.map(\.color))
        guard colors.count == players.count else {
            throw LudoError.duplicateColors
        }

        self.id = id
        self.started = started
        self.board = Board(playerCount: players.count)
        self.players = players

        var allTokens: [Token] = []
        for (playerIndex, player) in players.enumerated() {
            for tokenOffset in 0..<4 {
                let tokenID: TokenID = playerIndex * 4 + tokenOffset
                allTokens.append(Token(id: tokenID, playerID: player.id))
            }
        }
        self.tokens = allTokens
        self.state = .waitingForRoll(playerId: players[0].id)
    }

    /// Internal initializer for deterministic testing with pre-set token positions.
    init(
        id: String = UUID().uuidString,
        started: Date = .init(),
        players: [Player],
        tokenPositions: [Int],
        currentPlayerIndex: Int = 0
    ) throws {
        try self.init(id: id, started: started, players: players)
        for i in 0..<min(tokenPositions.count, tokens.count) {
            tokens[i].stepsFromBase = tokenPositions[i]
        }
        state = .waitingForRoll(playerId: players[currentPlayerIndex].id)
    }
}
