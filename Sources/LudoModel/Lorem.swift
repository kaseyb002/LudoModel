import Foundation

public enum Lorem {
    private static let firstNames: [String] = [
        "James", "Mary", "John", "Patricia", "Robert", "Jennifer",
        "Michael", "Linda", "William", "Elizabeth", "David", "Susan",
    ]

    private static let lastNames: [String] = [
        "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia",
        "Miller", "Davis", "Rodriguez", "Martinez", "Wilson", "Anderson",
    ]

    public static var fullName: String {
        "\(firstNames.randomElement()!) \(lastNames.randomElement()!)"
    }
}

extension URL {
    public static var randomImageURL: URL? {
        URL(string: "https://picsum.photos/id/\(Int.random(in: 1...200))/200/200")
    }
}
