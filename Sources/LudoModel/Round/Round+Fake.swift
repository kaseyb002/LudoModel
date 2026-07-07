import Foundation

extension Round {
    public static func fake(
        id: String = UUID().uuidString,
        started: Date = .init(),
        players: [Player]? = nil
    ) throws -> Round {
        let defaultPlayers: [Player] = [
            .fake(color: .red),
            .fake(color: .blue),
            .fake(color: .green),
            .fake(color: .yellow),
        ]
        return try .init(
            id: id,
            started: started,
            players: players ?? defaultPlayers
        )
    }
}
