import Foundation

public struct Board: Equatable, Codable, Sendable {
    public let playerCount: Int

    public var trackLength: Int { playerCount * 13 }
    public var homeColumnLength: Int { 6 }
    public var finishedStep: Int { trackLength + homeColumnLength + 1 }

    public init(playerCount: Int) {
        self.playerCount = playerCount
    }

    public func startAbsolutePosition(forPlayerIndex playerIndex: Int) -> Int {
        playerIndex * 13
    }

    /// Converts player-relative steps to an absolute board position on the main track.
    /// Returns nil if the token is not on the main track (in base, home column, or finished).
    public func absolutePosition(stepsFromBase: Int, playerIndex: Int) -> Int? {
        guard stepsFromBase >= 1, stepsFromBase <= trackLength else { return nil }
        return (startAbsolutePosition(forPlayerIndex: playerIndex) + stepsFromBase - 1) % trackLength
    }

    public func isInBase(_ stepsFromBase: Int) -> Bool {
        stepsFromBase == 0
    }

    public func isOnMainTrack(_ stepsFromBase: Int) -> Bool {
        stepsFromBase >= 1 && stepsFromBase <= trackLength
    }

    public func isInHomeColumn(_ stepsFromBase: Int) -> Bool {
        stepsFromBase > trackLength && stepsFromBase < finishedStep
    }

    public func isFinished(_ stepsFromBase: Int) -> Bool {
        stepsFromBase == finishedStep
    }

    /// Safe squares: each player's starting square plus one star square per section.
    public var safeSquarePositions: Set<Int> {
        var squares: Set<Int> = []
        for i in 0..<playerCount {
            let start: Int = startAbsolutePosition(forPlayerIndex: i)
            squares.insert(start)
            squares.insert((start + 8) % trackLength)
        }
        return squares
    }

    public func isSafeSquare(absolutePosition: Int) -> Bool {
        safeSquarePositions.contains(absolutePosition)
    }
}
