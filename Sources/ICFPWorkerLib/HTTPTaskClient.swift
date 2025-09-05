import Foundation
import FoundationNetworking

public class HTTPTaskClient {
    private let baseURL: String

    public init(url: String) {
        self.baseURL = url
    }

    public func getTask(id taskId: String) async throws -> Task {
        if let cachedTask = try? loadTask(id: taskId) {
            return cachedTask
        }

        let url = URL(string: "\(baseURL)/\(taskId)")!
        let request = URLRequest(url: url)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw URLError(.badServerResponse)
        }

        let task = try JSONDecoder().decode(Task.self, from: data)

        try storeTask(task)

        return task
    }

    private func storeTask(_ task: Task) throws {
        let fileManager = FileManager.default
        let tasksDir = URL(fileURLWithPath: "tasks")

        if !fileManager.fileExists(atPath: tasksDir.path) {
            try fileManager.createDirectory(at: tasksDir, withIntermediateDirectories: true)
        }

        let fileName = "\(task.id).json"
        let fileURL = tasksDir.appendingPathComponent(fileName)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(task)

        try jsonData.write(to: fileURL)
    }

    private func loadTask(id taskId: String) throws -> Task {
        let fileName = "\(taskId).json"
        let fileURL = URL(fileURLWithPath: "tasks").appendingPathComponent(fileName)

        let jsonData = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Task.self, from: jsonData)
    }
}
