import Foundation

extension Token {
    public static func fake(
        id: TokenID = Int.random(in: 0...100),
        playerID: PlayerID = UUID().uuidString,
        stepsFromBase: Int = 0
    ) -> Token {
        .init(id: id, playerID: playerID, stepsFromBase: stepsFromBase)
    }
}
