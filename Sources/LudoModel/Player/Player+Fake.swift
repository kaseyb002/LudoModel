import Foundation

extension Player {
    public static func fake(
        id: PlayerID = UUID().uuidString,
        name: String = Lorem.fullName,
        imageURL: URL? = .randomImageURL,
        color: PlayerColor = .allCases.randomElement()!
    ) -> Player {
        .init(id: id, name: name, imageURL: imageURL, color: color)
    }
}
