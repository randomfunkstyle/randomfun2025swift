import Foundation

public class EnvConfig {
    public let teamId: String
    public let apiUrl: String

    public init(fromFile path: String? = nil) {
        
        var path = path
        if path == nil {
            // Take from environment variable
            path = ProcessInfo.processInfo.environment["ICFP_CONFIG_PATH"]
        }
        
        if path == nil {
            // Default path
            path = ".env"
        }
        
        guard let path = path else {
            preconditionFailure("Path should not be nil here")
        }
        
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            teamId = "nil"
            apiUrl = "nil"
            return
        }

        var config: [String: String] = [:]

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            if let equalIndex = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[..<equalIndex]).trimmingCharacters(
                    in: .whitespacesAndNewlines)
                let value = String(trimmed[trimmed.index(after: equalIndex)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(
                        of: "^\"|\"$|^'|'$", with: "", options: .regularExpression)

                config[key] = value
            }
        }

        teamId = config["teamId"] ?? "nil"
        apiUrl = config["apiUrl"] ?? "nil"

        print("Loaded config: teamId=\(teamId), apiUrl=\(apiUrl)")
    }
}
