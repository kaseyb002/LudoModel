import Foundation
import Testing
@testable import LudoModel

// MARK: - Board Tests

@Test func boardLayout4Players() {
    let board: Board = Board(playerCount: 4)
    #expect(board.trackLength == 52)
    #expect(board.finishedStep == 59)
    #expect(board.safeSquarePositions.count == 8)
    #expect(board.safeSquarePositions.contains(0))
    #expect(board.safeSquarePositions.contains(13))
    #expect(board.safeSquarePositions.contains(26))
    #expect(board.safeSquarePositions.contains(39))
    #expect(board.safeSquarePositions.contains(8))
    #expect(board.safeSquarePositions.contains(21))
    #expect(board.safeSquarePositions.contains(34))
    #expect(board.safeSquarePositions.contains(47))
}

@Test func boardLayout6Players() {
    let board: Board = Board(playerCount: 6)
    #expect(board.trackLength == 78)
    #expect(board.finishedStep == 85)
    #expect(board.safeSquarePositions.count == 12)
}

@Test func boardLayout2Players() {
    let board: Board = Board(playerCount: 2)
    #expect(board.trackLength == 26)
    #expect(board.finishedStep == 33)
    #expect(board.safeSquarePositions.count == 4)
}

@Test func boardAbsolutePositions() {
    let board: Board = Board(playerCount: 4)
    #expect(board.absolutePosition(stepsFromBase: 1, playerIndex: 0) == 0)
    #expect(board.absolutePosition(stepsFromBase: 1, playerIndex: 1) == 13)
    #expect(board.absolutePosition(stepsFromBase: 1, playerIndex: 2) == 26)
    #expect(board.absolutePosition(stepsFromBase: 1, playerIndex: 3) == 39)
    #expect(board.absolutePosition(stepsFromBase: 14, playerIndex: 0) == 13)
    #expect(board.absolutePosition(stepsFromBase: 52, playerIndex: 0) == 51)
    #expect(board.absolutePosition(stepsFromBase: 53, playerIndex: 0) == nil)
    #expect(board.absolutePosition(stepsFromBase: 0, playerIndex: 0) == nil)
}

// MARK: - Round Init Tests

@Test func roundInitialization() throws {
    let players: [Player] = [
        .fake(id: "1", color: .red),
        .fake(id: "2", color: .blue),
    ]
    let round: Round = try .init(players: players)
    #expect(round.tokens.count == 8)
    #expect(round.tokens.filter { $0.isInBase }.count == 8)
    #expect(round.board.trackLength == 26)
    #expect(round.currentPlayerID == "1")
}

@Test func roundInitNotEnoughPlayers() {
    #expect(throws: LudoError.notEnoughPlayers) {
        try Round(players: [.fake(color: .red)])
    }
}

@Test func roundInitTooManyPlayers() {
    #expect(throws: LudoError.tooManyPlayers) {
        try Round(players: [
            .fake(id: "0", color: .red),
            .fake(id: "1", color: .blue),
            .fake(id: "2", color: .green),
            .fake(id: "3", color: .yellow),
            .fake(id: "4", color: .purple),
            .fake(id: "5", color: .orange),
            .fake(id: "6", color: .red),
        ])
    }
}

@Test func roundInitDuplicateColors() {
    #expect(throws: LudoError.duplicateColors) {
        try Round(players: [.fake(id: "1", color: .red), .fake(id: "2", color: .red)])
    }
}

// MARK: - Basic Movement Tests

@Test func bringTokenOutOfBase() throws {
    var round: Round = try .init(players: [
        .fake(id: "1", color: .red),
        .fake(id: "2", color: .blue),
    ])

    try round.rollDie(cookedValue: 6)
    #expect(round.state == .waitingForTokenChoice(playerId: "1", dieValue: 6))

    let legalMoves: [TokenID] = round.getLegalMoves(playerID: "1", dieValue: 6)
    #expect(legalMoves.count == 4)

    try round.moveToken(tokenID: 0)
    #expect(round.tokens[0].stepsFromBase == 1)
    #expect(round.currentPlayerID == "1")
}

@Test func cannotMoveWithoutSix() throws {
    var round: Round = try .init(players: [
        .fake(id: "1", color: .red),
        .fake(id: "2", color: .blue),
    ])

    try round.rollDie(cookedValue: 3)
    #expect(round.currentPlayerID == "2")
}

@Test func normalMovement() throws {
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [5, 0, 0, 0, 0, 0, 0, 0]
    )

    try round.rollDie(cookedValue: 4)
    try round.moveToken(tokenID: 0)
    #expect(round.tokens[0].stepsFromBase == 9)
    #expect(round.currentPlayerID == "2")
}

// MARK: - Capture Tests

@Test func captureOnUnsafeSquare() throws {
    // 2-player game: trackLength=26
    // Player 0 (index 0): start abs pos = 0
    // Player 1 (index 1): start abs pos = 13
    // Safe squares: {0, 8, 13, 21}
    //
    // Player 0 token at step 5 → abs pos 4 (unsafe)
    // Player 1 token at step 17 → abs pos (13+17-1)%26 = 29%26 = 3
    // Player 1 rolls 1 → step 18 → abs pos (13+18-1)%26 = 30%26 = 4 → CAPTURE
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [5, 0, 0, 0, 17, 0, 0, 0],
        currentPlayerIndex: 1
    )

    try round.rollDie(cookedValue: 1)
    try round.moveToken(tokenID: 4)
    #expect(round.tokens[0].stepsFromBase == 0)
    #expect(round.tokens[4].stepsFromBase == 18)
    #expect(round.currentPlayerID == "2")
}

@Test func noCaptureOnSafeSquare() throws {
    // Player 0 token at step 9 → abs pos (0+9-1)%26 = 8 (star safe square)
    // Player 1 token at step 21 → abs pos (13+21-1)%26 = 33%26 = 7
    // Player 1 rolls 1 → step 22 → abs pos (13+22-1)%26 = 34%26 = 8 → safe, NO capture
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [9, 0, 0, 0, 21, 0, 0, 0],
        currentPlayerIndex: 1
    )

    try round.rollDie(cookedValue: 1)
    try round.moveToken(tokenID: 4)
    #expect(round.tokens[0].stepsFromBase == 9)
    #expect(round.tokens[4].stepsFromBase == 22)
}

@Test func noCaptureOnStartSquare() throws {
    // Player 0 start abs pos = 0 (safe)
    // Player 0 token at step 1 → abs pos 0 (player 0's start, safe)
    // Player 1 at step 14 → abs pos (13+14-1)%26 = 26%26 = 0
    // Wait, that's wrong. Let me recalculate.
    // Player 1 at step S → abs pos (13+S-1)%26 = 0
    // 13+S-1 = 0+26 = 26 → S=14
    // Player 1 at step 13 → abs pos (13+13-1)%26 = 25%26 = 25
    // Player 1 rolls 1 → step 14 → abs pos 0 → safe, no capture
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [1, 0, 0, 0, 13, 0, 0, 0],
        currentPlayerIndex: 1
    )

    try round.rollDie(cookedValue: 1)
    try round.moveToken(tokenID: 4)
    #expect(round.tokens[0].stepsFromBase == 1)
    #expect(round.tokens[4].stepsFromBase == 14)
}

// MARK: - Blockade Tests

@Test func blockadePreventsLanding() throws {
    // Player 1 has 2 tokens at abs pos 4 (blockade)
    // Player 1 (index 1, start abs pos 13):
    //   step S → abs pos (13+S-1)%26 = 4 → S = 4-13+1+26 = 18
    // Player 0 token at step 3 → abs pos 2
    // Player 0 rolls 2 → would land on step 5, abs pos 4 → BLOCKED by blockade
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [3, 0, 0, 0, 18, 18, 0, 0]
    )

    try round.rollDie(cookedValue: 2)
    let legalMoves: [TokenID] = round.getLegalMoves(playerID: "1", dieValue: 2)
    #expect(legalMoves.contains(0) == false)
}

@Test func blockadePreventsPassing() throws {
    // Player 1 blockade at abs pos 4
    // Player 0 token at step 3 → abs pos 2
    // Player 0 rolls 5 → would pass through abs pos 4 (step 5) → BLOCKED
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [3, 0, 0, 0, 18, 18, 0, 0]
    )

    try round.rollDie(cookedValue: 5)
    let legalMoves: [TokenID] = round.getLegalMoves(playerID: "1", dieValue: 5)
    #expect(legalMoves.contains(0) == false)
}

// MARK: - Bonus Roll Tests

@Test func bonusRollOnSix() throws {
    var round: Round = try .init(players: [
        .fake(id: "1", color: .red),
        .fake(id: "2", color: .blue),
    ])

    try round.rollDie(cookedValue: 6)
    try round.moveToken(tokenID: 0)
    #expect(round.currentPlayerID == "1")

    try round.rollDie(cookedValue: 3)
    try round.moveToken(tokenID: 0)
    #expect(round.tokens[0].stepsFromBase == 4)
    #expect(round.currentPlayerID == "2")
}

@Test func bonusRollOnCapture() throws {
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [5, 0, 0, 0, 17, 0, 0, 0],
        currentPlayerIndex: 1
    )

    try round.rollDie(cookedValue: 1)
    try round.moveToken(tokenID: 4)
    #expect(round.tokens[0].stepsFromBase == 0)
    #expect(round.currentPlayerID == "2")
}

// MARK: - Three Consecutive Sixes

@Test func threeConsecutiveSixes() throws {
    var round: Round = try .init(players: [
        .fake(id: "1", color: .red),
        .fake(id: "2", color: .blue),
    ])

    // First 6: bring token out
    try round.rollDie(cookedValue: 6)
    try round.moveToken(tokenID: 0)
    #expect(round.consecutiveSixes == 1)

    // Second 6: bring another token out
    try round.rollDie(cookedValue: 6)
    try round.moveToken(tokenID: 1)
    #expect(round.consecutiveSixes == 2)

    // Third 6: penalty, turn ends
    try round.rollDie(cookedValue: 6)
    #expect(round.currentPlayerID == "2")
    #expect(round.consecutiveSixes == 0)
}

@Test func consecutiveSixesResetOnNonSix() throws {
    var round: Round = try .init(players: [
        .fake(id: "1", color: .red),
        .fake(id: "2", color: .blue),
    ])

    try round.rollDie(cookedValue: 6)
    try round.moveToken(tokenID: 0)
    #expect(round.consecutiveSixes == 1)

    try round.rollDie(cookedValue: 3)
    try round.moveToken(tokenID: 0)
    #expect(round.consecutiveSixes == 0)
    #expect(round.currentPlayerID == "2")
}

// MARK: - Home Entry Tests

@Test func exactHomeEntry() throws {
    // 2-player game: finishedStep = 33
    // Token at step 30 (in home column), roll 3 → step 33 = finished!
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [30, 0, 0, 0, 0, 0, 0, 0]
    )

    try round.rollDie(cookedValue: 3)
    try round.moveToken(tokenID: 0)
    #expect(round.tokens[0].stepsFromBase == 33)
    #expect(round.board.isFinished(round.tokens[0].stepsFromBase))
}

@Test func cannotOvershootHome() throws {
    // Token at step 30, roll 5 → step 35 > finishedStep(33) → illegal
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [30, 0, 0, 0, 0, 0, 0, 0]
    )

    try round.rollDie(cookedValue: 5)
    let legalMoves: [TokenID] = round.getLegalMoves(playerID: "1", dieValue: 5)
    #expect(legalMoves.contains(0) == false)
}

@Test func homeColumnEntry() throws {
    // 2-player game: trackLength=26
    // Token at step 25 (still on main track), roll 3 → step 28 (home column)
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [25, 0, 0, 0, 0, 0, 0, 0]
    )

    try round.rollDie(cookedValue: 3)
    try round.moveToken(tokenID: 0)
    #expect(round.tokens[0].stepsFromBase == 28)
    #expect(round.board.isInHomeColumn(28))
}

// MARK: - Game Completion Tests

@Test func playerFinishesAllTokens() throws {
    // All 4 tokens of player 1 at step 32 (one step from home), finishedStep=33
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [33, 33, 33, 32, 0, 0, 0, 0]
    )

    try round.rollDie(cookedValue: 1)
    try round.moveToken(tokenID: 3)
    #expect(round.tokens[3].stepsFromBase == 33)
    #expect(round.rankings.contains("1"))
}

@Test func gameCompletesWhenAllFinish() throws {
    // Player 1 has all tokens finished, player 2 has 3 finished and 1 at step 32
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [33, 33, 33, 33, 33, 33, 33, 32],
        currentPlayerIndex: 1
    )
    round.rankings = ["1"]

    try round.rollDie(cookedValue: 1)
    try round.moveToken(tokenID: 7)
    #expect(round.isGameComplete)
    #expect(round.rankings == ["1", "2"])
}

// MARK: - Full Game Playthrough

@Test func fullGamePlaythrough() throws {
    var round: Round = try .init(players: [
        .fake(id: "1", name: "Alice", color: .red),
        .fake(id: "2", name: "Bob", color: .blue),
    ])

    // Script die rolls for a deterministic game
    // Strategy: bring all tokens out, then march them home
    var moveCount: Int = 0
    let maxMoves: Int = 2000

    while round.isGameComplete == false, moveCount < maxMoves {
        guard case .waitingForRoll(let playerID) = round.state else { break }

        let dieValue: Int
        let playerTokens: [Token] = round.tokens(for: playerID)
        let allInBase: Bool = playerTokens.allSatisfy(\.isInBase)
        let anyInBase: Bool = playerTokens.contains(where: \.isInBase)
        let anyNearHome: Bool = playerTokens.contains(where: {
            let remaining: Int = round.board.finishedStep - $0.stepsFromBase
            return remaining > 0 && remaining <= 6
        })

        if allInBase || (anyInBase && round.consecutiveSixes < 2) {
            dieValue = 6
        } else if anyNearHome {
            let nearHomeToken: Token = playerTokens.first(where: {
                let remaining: Int = round.board.finishedStep - $0.stepsFromBase
                return remaining > 0 && remaining <= 6
            })!
            dieValue = round.board.finishedStep - nearHomeToken.stepsFromBase
        } else {
            dieValue = 5
        }

        try round.rollDie(cookedValue: dieValue)

        if case .waitingForTokenChoice(let pid, let die) = round.state {
            let legalMoves: [TokenID] = round.getLegalMoves(playerID: pid, dieValue: die)
            if legalMoves.isEmpty == false {
                // Prefer finishing tokens, then advancing farthest token
                let bestToken: TokenID = legalMoves.max(by: { a, b in
                    let tokenA: Token = round.tokens.first(where: { $0.id == a })!
                    let tokenB: Token = round.tokens.first(where: { $0.id == b })!
                    return tokenA.stepsFromBase < tokenB.stepsFromBase
                })!
                try round.moveToken(tokenID: bestToken)
            }
        }

        moveCount += 1
    }

    #expect(round.isGameComplete)
    #expect(round.rankings.count == 2)
    #expect(round.winner != nil)
}

// MARK: - AI Tests

@Test func aiMakesValidMoves() throws {
    for difficulty in AIDifficulty.allCases {
        var round: Round = try .init(players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ])

        var moveCount: Int = 0
        let maxMoves: Int = 500

        while round.isGameComplete == false, moveCount < maxMoves {
            round = try round.makeAIMove(difficulty: difficulty)
            moveCount += 1
        }

        #expect(round.isGameComplete, "Game should complete with \(difficulty) AI within \(maxMoves) moves")
    }
}

@Test func aiDoesNotCheat() throws {
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [10, 0, 0, 0, 5, 0, 0, 0]
    )

    // Roll a 3 for player 1
    try round.rollDie(cookedValue: 3)

    if case .waitingForTokenChoice(let playerID, let dieValue) = round.state {
        let legalMoves: [TokenID] = round.getLegalMoves(playerID: playerID, dieValue: dieValue)

        let roundBefore: Round = round
        let aiRound: Round = try round.makeAIMove(difficulty: .hard)

        for i in 0..<aiRound.tokens.count {
            if aiRound.tokens[i].stepsFromBase != roundBefore.tokens[i].stepsFromBase {
                #expect(legalMoves.contains(aiRound.tokens[i].id))
            }
        }
    }
}

// MARK: - Edge Case Tests

@Test func invalidDieValue() throws {
    var round: Round = try .init(players: [
        .fake(id: "1", color: .red),
        .fake(id: "2", color: .blue),
    ])

    #expect(throws: LudoError.invalidDieValue) {
        try round.rollDie(cookedValue: 0)
    }
    #expect(throws: LudoError.invalidDieValue) {
        try round.rollDie(cookedValue: 7)
    }
}

@Test func cannotRollWhenNotWaiting() throws {
    var round: Round = try .init(players: [
        .fake(id: "1", color: .red),
        .fake(id: "2", color: .blue),
    ])

    try round.rollDie(cookedValue: 6)
    // Now in waitingForTokenChoice, should not be able to roll again
    #expect(throws: LudoError.notWaitingForRoll) {
        try round.rollDie(cookedValue: 3)
    }
}

@Test func cannotMoveIllegalToken() throws {
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [5, 0, 0, 0, 0, 0, 0, 0]
    )

    try round.rollDie(cookedValue: 3)
    // Token 1 is in base, can't move with a 3
    #expect(throws: LudoError.illegalMove) {
        try round.moveToken(tokenID: 1)
    }
}

@Test func cannotMoveOpponentToken() throws {
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [5, 0, 0, 0, 5, 0, 0, 0]
    )

    try round.rollDie(cookedValue: 3)
    #expect(throws: LudoError.tokenDoesNotBelongToPlayer) {
        try round.moveToken(tokenID: 4)
    }
}

@Test func logMaxActions() throws {
    var round: Round = try .init(
        players: [
            .fake(id: "1", color: .red),
            .fake(id: "2", color: .blue),
        ],
        tokenPositions: [5, 0, 0, 0, 5, 0, 0, 0]
    )

    // Play enough moves to exceed 100 log entries
    for _ in 0..<60 {
        guard round.isGameComplete == false else { break }
        if case .waitingForRoll = round.state {
            try round.rollDie(cookedValue: 1)
            if case .waitingForTokenChoice(_, let die) = round.state {
                let moves: [TokenID] = round.getLegalMoves(
                    playerID: round.currentPlayerID!,
                    dieValue: die
                )
                if moves.isEmpty == false {
                    try round.moveToken(tokenID: moves[0])
                }
            }
        }
    }

    #expect(round.log.actions.count <= 100)
}

@Test func fakeRound() throws {
    let round: Round = try .fake()
    #expect(round.players.count == 4)
    #expect(round.tokens.count == 16)
}

@Test func fakePlayer() {
    let player: Player = .fake()
    #expect(player.name.isEmpty == false)
    #expect(player.id.isEmpty == false)
}

@Test func fakeToken() {
    let token: Token = .fake()
    #expect(token.isInBase)
}

@Test func sixPlayerGame() throws {
    let players: [Player] = [
        .fake(id: "1", color: .red),
        .fake(id: "2", color: .blue),
        .fake(id: "3", color: .green),
        .fake(id: "4", color: .yellow),
        .fake(id: "5", color: .purple),
        .fake(id: "6", color: .orange),
    ]
    let round: Round = try .init(players: players)
    #expect(round.tokens.count == 24)
    #expect(round.board.trackLength == 78)
    #expect(round.board.finishedStep == 85)
}
