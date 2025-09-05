import Foundation

public struct Task: Codable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

