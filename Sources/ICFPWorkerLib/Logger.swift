import Foundation

public class GraphNode: Codable {
    let nodeId: Int
    let roomLabel: Int
    let roomIndex: Int?
    var doors: [Int?]

    init(nodeId: Int, roomLabel: Int, roomIndex: Int?, doors: [Int?]) {
        self.nodeId = nodeId
        self.roomLabel = roomLabel
        self.roomIndex = roomIndex
        self.doors = doors
    }
}

public class LogState: Codable {
    var graphBefore: [GraphNode]
    var graphAfter: [GraphNode]

    var query: String
    var result: [Int]
    var isPingQuery: Bool

    init(
        graphBefore: [GraphNode], graphAfter: [GraphNode],
        query: String, result: [Int], isPingQuery: Bool
    ) {
        self.graphBefore = graphBefore
        self.graphAfter = graphAfter
        self.query = query
        self.result = result
        self.isPingQuery = isPingQuery
    }
}

public class Logger {
    let file: String

    static let shared = Logger()

    private init() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        self.file = "\(dateString).json"
    }

    func log(logState: LogState) {
//        print("📝 Logging state...")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let data: Data

        do {
            data = try encoder.encode(logState)
        } catch {
            print("❌ Failed to encode log state to JSON: \(error.localizedDescription)")
            return
        }

        guard
            let jsonString = String(data: data, encoding: .utf8)?.replacingOccurrences(
                of: "\n", with: "")
        else {
            print("❌ Failed to convert JSON data to string")
            return
        }

        let currentDirectory = FileManager.default.currentDirectoryPath
        let fileURL = URL(fileURLWithPath: currentDirectory).appendingPathComponent(file)

        let finalString = jsonString + "\n"

        do {
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                if let dataToWrite = finalString.data(using: .utf8) {
                    fileHandle.write(dataToWrite)
                } else {
                    print("❌ Failed to convert final string to data for appending")
                }
                fileHandle.closeFile()
            } else {
                try finalString.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("❌ Failed to write to file: \(error.localizedDescription)")
        }

//        print("✅ Logged state to: \(fileURL.path)")
    }
}
