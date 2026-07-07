import Foundation

public enum AIDifficulty: String, CaseIterable, Equatable, Codable, Sendable {
    case easy
    case medium
    case hard
}

extension Round {

    /// Performs one AI action step: rolls the die (if needed) and chooses a token to move.
    /// Call repeatedly while the same player is active to handle bonus rolls.
    public func makeAIMove(difficulty: AIDifficulty) throws -> Round {
        var round: Round = self

        switch round.state {
        case .waitingForRoll:
            try round.rollDie()
            if case .waitingForTokenChoice = round.state {
                try round.makeAITokenChoice(difficulty: difficulty)
            }

        case .waitingForTokenChoice:
            try round.makeAITokenChoice(difficulty: difficulty)

        case .roundComplete:
            break
        }

        return round
    }

    private mutating func makeAITokenChoice(difficulty: AIDifficulty) throws {
        guard case .waitingForTokenChoice(let playerID, let dieValue) = state else { return }

        let legalMoves: [TokenID] = getLegalMoves(playerID: playerID, dieValue: dieValue)
        guard legalMoves.isEmpty == false else { return }

        let chosenTokenID: TokenID
        switch difficulty {
        case .easy:
            chosenTokenID = legalMoves.randomElement()!

        case .medium:
            chosenTokenID = chooseMediumMove(
                playerID: playerID,
                dieValue: dieValue,
                legalMoves: legalMoves
            )

        case .hard:
            chosenTokenID = chooseHardMove(
                playerID: playerID,
                dieValue: dieValue,
                legalMoves: legalMoves
            )
        }

        try moveToken(tokenID: chosenTokenID)
    }

    // MARK: - Medium AI

    private func chooseMediumMove(playerID: PlayerID, dieValue: Int, legalMoves: [TokenID]) -> TokenID {
        guard let playerIdx: Int = playerIndex(for: playerID) else {
            return legalMoves.randomElement()!
        }

        var bestToken: TokenID = legalMoves[0]
        var bestScore: Int = Int.min

        for tokenID in legalMoves {
            let score: Int = scoreMoveForMedium(
                tokenID: tokenID,
                playerID: playerID,
                playerIndex: playerIdx,
                dieValue: dieValue
            )
            if score > bestScore {
                bestScore = score
                bestToken = tokenID
            }
        }

        return bestToken
    }

    private func scoreMoveForMedium(
        tokenID: TokenID,
        playerID: PlayerID,
        playerIndex playerIdx: Int,
        dieValue: Int
    ) -> Int {
        guard let token: Token = tokens.first(where: { $0.id == tokenID }) else { return 0 }

        var score: Int = 0
        let newSteps: Int = token.isInBase ? 1 : token.stepsFromBase + dieValue

        if board.isOnMainTrack(newSteps),
           let absPos: Int = board.absolutePosition(stepsFromBase: newSteps, playerIndex: playerIdx),
           board.isSafeSquare(absolutePosition: absPos) == false {
            let opponentCount: Int = countOpponentTokens(at: absPos, excludingPlayer: playerID)
            if opponentCount > 0 {
                score += 100
            }
        }

        if board.isFinished(newSteps) {
            score += 90
        }

        if board.isInHomeColumn(newSteps) && board.isOnMainTrack(token.stepsFromBase) {
            score += 70
        }

        if token.stepsFromBase == 1 && newSteps > 1 {
            score += 40
        }

        if token.isInBase {
            score += 30
        }

        score += newSteps

        return score
    }

    // MARK: - Hard AI

    private func chooseHardMove(playerID: PlayerID, dieValue: Int, legalMoves: [TokenID]) -> TokenID {
        guard let playerIdx: Int = playerIndex(for: playerID) else {
            return legalMoves.randomElement()!
        }

        var bestToken: TokenID = legalMoves[0]
        var bestScore: Int = Int.min

        for tokenID in legalMoves {
            let score: Int = scoreMoveForHard(
                tokenID: tokenID,
                playerID: playerID,
                playerIndex: playerIdx,
                dieValue: dieValue
            )
            if score > bestScore {
                bestScore = score
                bestToken = tokenID
            }
        }

        return bestToken
    }

    private func scoreMoveForHard(
        tokenID: TokenID,
        playerID: PlayerID,
        playerIndex playerIdx: Int,
        dieValue: Int
    ) -> Int {
        guard let token: Token = tokens.first(where: { $0.id == tokenID }) else { return 0 }

        var score: Int = scoreMoveForMedium(
            tokenID: tokenID,
            playerID: playerID,
            playerIndex: playerIdx,
            dieValue: dieValue
        )
        let newSteps: Int = token.isInBase ? 1 : token.stepsFromBase + dieValue

        guard board.isOnMainTrack(newSteps),
              let absPos: Int = board.absolutePosition(stepsFromBase: newSteps, playerIndex: playerIdx)
        else {
            return score
        }

        if board.isSafeSquare(absolutePosition: absPos) {
            score += 50
        }

        if board.isSafeSquare(absolutePosition: absPos) == false {
            for opToken in tokens {
                guard opToken.playerID != playerID,
                      board.isOnMainTrack(opToken.stepsFromBase),
                      let opIdx: Int = playerIndex(for: opToken.playerID),
                      let opAbsPos: Int = board.absolutePosition(
                          stepsFromBase: opToken.stepsFromBase,
                          playerIndex: opIdx
                      )
                else { continue }

                let dist: Int = (absPos - opAbsPos + board.trackLength) % board.trackLength
                if dist >= 1 && dist <= 6 {
                    score -= 30
                }
            }
        }

        let friendlyCount: Int = countFriendlyTokens(
            at: absPos,
            forPlayer: playerID,
            excludingToken: tokenID
        )
        if friendlyCount >= 1 {
            score += 35
        }

        return score
    }

    // MARK: - Helpers

    private func countOpponentTokens(at absolutePosition: Int, excludingPlayer playerID: PlayerID) -> Int {
        var count: Int = 0
        for token in tokens {
            guard token.playerID != playerID,
                  board.isOnMainTrack(token.stepsFromBase),
                  let tokPlayerIdx: Int = playerIndex(for: token.playerID),
                  let absPos: Int = board.absolutePosition(
                      stepsFromBase: token.stepsFromBase,
                      playerIndex: tokPlayerIdx
                  )
            else { continue }
            if absPos == absolutePosition {
                count += 1
            }
        }
        return count
    }

    private func countFriendlyTokens(
        at absolutePosition: Int,
        forPlayer playerID: PlayerID,
        excludingToken tokenID: TokenID
    ) -> Int {
        var count: Int = 0
        for token in tokens {
            guard token.id != tokenID,
                  token.playerID == playerID,
                  board.isOnMainTrack(token.stepsFromBase),
                  let tokPlayerIdx: Int = playerIndex(for: token.playerID),
                  let absPos: Int = board.absolutePosition(
                      stepsFromBase: token.stepsFromBase,
                      playerIndex: tokPlayerIdx
                  )
            else { continue }
            if absPos == absolutePosition {
                count += 1
            }
        }
        return count
    }
}
