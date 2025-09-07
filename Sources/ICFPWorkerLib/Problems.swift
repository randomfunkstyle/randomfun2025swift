public struct Problem {

    public let roomsCount: Int
    public let name: String
    public let complicated: Bool

    public static let probatio = Problem(roomsCount: 3, name: "probatio", complicated: false)
    public static let primus = Problem(roomsCount: 6, name: "primus", complicated: false)
    public static let secundus = Problem(roomsCount: 12, name: "secundus", complicated: false)
    public static let tertius = Problem(roomsCount: 18, name: "tertius", complicated: false)
    public static let quartus = Problem(roomsCount: 24, name: "quartus", complicated: false)
    public static let quintus = Problem(roomsCount: 30, name: "quintus", complicated: false)

    public static let aleph = Problem(roomsCount: 12, name: "aleph", complicated: true)
    public static let beth = Problem(roomsCount: 24, name: "beth", complicated: true)
    public static let gimel = Problem(roomsCount: 36, name: "gimel", complicated: true)
    public static let daleth = Problem(roomsCount: 48, name: "daleth", complicated: true)
    public static let he = Problem(roomsCount: 60, name: "he", complicated: true)
    public static let vau = Problem(roomsCount: 18, name: "vau", complicated: true)
    public static let zain = Problem(roomsCount: 36, name: "zain", complicated: true)
    public static let hhet = Problem(roomsCount: 54, name: "hhet", complicated: true)
    public static let teth = Problem(roomsCount: 72, name: "teth", complicated: true)
    public static let iod = Problem(roomsCount: 90, name: "iod", complicated: true)
}

