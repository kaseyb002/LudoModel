import Foundation

extension Round {

    // MARK: - Public Actions

    public mutating func rollDie(cookedValue: Int? = nil) throws {
        guard case .waitingForRoll(let playerID) = state else {
            throw LudoError.notWaitingForRoll
        }

        let dieValue: Int
        if let cooked: Int = cookedValue {
            guard cooked >= 1, cooked <= 6 else {
                throw LudoError.invalidDieValue
            }
            dieValue = cooked
        } else {
            dieValue = Int.random(in: 1...6)
        }

        log.addAction(.init(playerID: playerID, decision: .rolled(dieValue: dieValue)))

        if dieValue == 6 {
            consecutiveSixes += 1
            if consecutiveSixes >= 3 {
                log.addAction(.init(playerID: playerID, decision: .threeConsecutiveSixes))
                advanceToNextPlayer(currentPlayerID: playerID)
                return
            }
        } else {
            consecutiveSixes = 0
        }

        guard let playerIdx: Int = playerIndex(for: playerID) else {
            throw LudoError.tokenNotFound
        }

        let legalMoves: [TokenID] = computeLegalMoves(
            playerID: playerID,
            playerIndex: playerIdx,
            dieValue: dieValue
        )

        if legalMoves.isEmpty {
            log.addAction(.init(playerID: playerID, decision: .noLegalMove))
            if dieValue == 6 {
                state = .waitingForRoll(playerId: playerID)
            } else {
                advanceToNextPlayer(currentPlayerID: playerID)
            }
            return
        }

        state = .waitingForTokenChoice(playerId: playerID, dieValue: dieValue)
    }

    public mutating func moveToken(tokenID: TokenID) throws {
        guard case .waitingForTokenChoice(let playerID, let dieValue) = state else {
            throw LudoError.notWaitingForTokenChoice
        }

        guard let playerIdx: Int = playerIndex(for: playerID) else {
            throw LudoError.tokenNotFound
        }

        guard let tokenIndex: Int = tokens.firstIndex(where: { $0.id == tokenID }) else {
            throw LudoError.tokenNotFound
        }

        guard tokens[tokenIndex].playerID == playerID else {
            throw LudoError.tokenDoesNotBelongToPlayer
        }

        let legalMoves: [TokenID] = computeLegalMoves(
            playerID: playerID,
            playerIndex: playerIdx,
            dieValue: dieValue
        )
        guard legalMoves.contains(tokenID) else {
            throw LudoError.illegalMove
        }

        let newSteps: Int
        if tokens[tokenIndex].isInBase {
            newSteps = 1
            tokens[tokenIndex].stepsFromBase = newSteps
            log.addAction(.init(playerID: playerID, decision: .movedOutOfBase(tokenId: tokenID)))
        } else {
            newSteps = tokens[tokenIndex].stepsFromBase + dieValue
            tokens[tokenIndex].stepsFromBase = newSteps
            log.addAction(.init(playerID: playerID, decision: .movedToken(tokenId: tokenID, stepsFromBase: newSteps)))
        }

        var didCapture: Bool = false

        if board.isOnMainTrack(newSteps) {
            if let absPos: Int = board.absolutePosition(stepsFromBase: newSteps, playerIndex: playerIdx),
               board.isSafeSquare(absolutePosition: absPos) == false {
                for i in 0..<tokens.count {
                    guard tokens[i].playerID != playerID,
                          board.isOnMainTrack(tokens[i].stepsFromBase),
                          let opponentPlayerIdx: Int = playerIndex(for: tokens[i].playerID),
                          let opponentAbsPos: Int = board.absolutePosition(
                              stepsFromBase: tokens[i].stepsFromBase,
                              playerIndex: opponentPlayerIdx
                          ),
                          opponentAbsPos == absPos
                    else { continue }

                    let capturedTokenID: TokenID = tokens[i].id
                    tokens[i].stepsFromBase = 0
                    log.addAction(.init(
                        playerID: playerID,
                        decision: .capturedOpponent(tokenId: tokenID, capturedTokenId: capturedTokenID)
                    ))
                    didCapture = true
                }
            }
        }

        if board.isFinished(newSteps) {
            log.addAction(.init(playerID: playerID, decision: .enteredHome(tokenId: tokenID)))

            if allTokensFinished(for: playerID) {
                rankings.append(playerID)

                let unfinishedPlayers: [PlayerID] = players
                    .map(\.id)
                    .filter { rankings.contains($0) == false }

                if unfinishedPlayers.count <= 1 {
                    for pid in unfinishedPlayers {
                        rankings.append(pid)
                    }
                    state = .roundComplete
                    ended = .init()
                    return
                }

                advanceToNextPlayer(currentPlayerID: playerID)
                return
            }
        }

        if dieValue == 6 || didCapture {
            state = .waitingForRoll(playerId: playerID)
        } else {
            advanceToNextPlayer(currentPlayerID: playerID)
        }
    }

    // MARK: - Legal Moves

    public func getLegalMoves(playerID: PlayerID, dieValue: Int) -> [TokenID] {
        guard let playerIdx: Int = playerIndex(for: playerID) else { return [] }
        return computeLegalMoves(playerID: playerID, playerIndex: playerIdx, dieValue: dieValue)
    }

    func computeLegalMoves(playerID: PlayerID, playerIndex playerIdx: Int, dieValue: Int) -> [TokenID] {
        let playerTokens: [Token] = tokens.filter { $0.playerID == playerID }
        var legalTokenIDs: [TokenID] = []

        for token in playerTokens {
            if token.isInBase {
                guard dieValue == 6 else { continue }
                let startAbsPos: Int = board.startAbsolutePosition(forPlayerIndex: playerIdx)
                if isBlockedByOpponentBlockade(absolutePosition: startAbsPos, playerID: playerID) == false {
                    legalTokenIDs.append(token.id)
                }
            } else if board.isFinished(token.stepsFromBase) {
                continue
            } else {
                let newSteps: Int = token.stepsFromBase + dieValue

                if newSteps > board.finishedStep {
                    continue
                }

                if isPathBlocked(
                    from: token.stepsFromBase,
                    steps: dieValue,
                    playerIndex: playerIdx,
                    playerID: playerID
                ) {
                    continue
                }

                if board.isOnMainTrack(newSteps) {
                    if let destAbsPos: Int = board.absolutePosition(stepsFromBase: newSteps, playerIndex: playerIdx),
                       isBlockedByOpponentBlockade(absolutePosition: destAbsPos, playerID: playerID) {
                        continue
                    }
                }

                legalTokenIDs.append(token.id)
            }
        }

        return legalTokenIDs
    }

    // MARK: - Blockade Detection

    func isBlockedByOpponentBlockade(absolutePosition: Int, playerID: PlayerID) -> Bool {
        var opponentCounts: [PlayerID: Int] = [:]
        for token in tokens {
            guard token.playerID != playerID, board.isOnMainTrack(token.stepsFromBase) else { continue }
            guard let tokPlayerIdx: Int = playerIndex(for: token.playerID),
                  let absPos: Int = board.absolutePosition(stepsFromBase: token.stepsFromBase, playerIndex: tokPlayerIdx)
            else { continue }
            if absPos == absolutePosition {
                opponentCounts[token.playerID, default: 0] += 1
            }
        }
        return opponentCounts.values.contains(where: { $0 >= 2 })
    }

    func isPathBlocked(from stepsFromBase: Int, steps: Int, playerIndex: Int, playerID: PlayerID) -> Bool {
        for step in 1..<steps {
            let intermediateSteps: Int = stepsFromBase + step
            guard board.isOnMainTrack(intermediateSteps) else { continue }
            guard let absPos: Int = board.absolutePosition(stepsFromBase: intermediateSteps, playerIndex: playerIndex)
            else { continue }
            if isBlockedByOpponentBlockade(absolutePosition: absPos, playerID: playerID) {
                return true
            }
        }
        return false
    }

    // MARK: - Turn Management

    private mutating func advanceToNextPlayer(currentPlayerID: PlayerID) {
        consecutiveSixes = 0

        guard let currentIndex: Int = players.firstIndex(where: { $0.id == currentPlayerID }) else { return }

        let unfinishedPlayers: [Player] = players.filter { rankings.contains($0.id) == false }
        if unfinishedPlayers.count <= 1 {
            for player in unfinishedPlayers where rankings.contains(player.id) == false {
                rankings.append(player.id)
            }
            state = .roundComplete
            ended = .init()
            return
        }

        var nextIndex: Int = (currentIndex + 1) % players.count
        var checked: Int = 0
        while rankings.contains(players[nextIndex].id) {
            nextIndex = (nextIndex + 1) % players.count
            checked += 1
            if checked >= players.count {
                break
            }
        }

        state = .waitingForRoll(playerId: players[nextIndex].id)
    }
}
