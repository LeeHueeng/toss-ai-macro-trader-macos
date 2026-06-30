import Foundation

enum AICommandRunnerError: LocalizedError {
    case emptyCommand
    case executionFailed(Int32, String)

    var errorDescription: String? {
        switch self {
        case .emptyCommand:
            "AI 명령어가 비어 있습니다"
        case .executionFailed(let code, let output):
            "명령어가 종료 코드 \(code)로 실패했습니다: \(output)"
        }
    }
}

struct AICommandRunner {
    func run(command: String, stdin: String) async throws -> String {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AICommandRunnerError.emptyCommand
        }
        let shellCommand = sanitizedShellCommand(trimmed)

        return try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lc", shellCommand]
            let workspaceURL = URL(fileURLWithPath: "/Volumes/develop/toss_chart", isDirectory: true)
            if FileManager.default.fileExists(atPath: workspaceURL.path) {
                process.currentDirectoryURL = workspaceURL
            }
            process.environment = environmentWithCLIPaths()

            let input = Pipe()
            let output = Pipe()
            let error = Pipe()
            process.standardInput = input
            process.standardOutput = output
            process.standardError = error

            try process.run()
            input.fileHandleForWriting.write(Data(stdin.utf8))
            try? input.fileHandleForWriting.close()
            process.waitUntilExit()

            let outputData = output.fileHandleForReading.readDataToEndOfFile()
            let errorData = error.fileHandleForReading.readDataToEndOfFile()
            let combined = [
                String(data: outputData, encoding: .utf8),
                String(data: errorData, encoding: .utf8)
            ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")

            guard process.terminationStatus == 0 else {
                throw AICommandRunnerError.executionFailed(process.terminationStatus, combined)
            }

            return combined.isEmpty ? "명령어가 출력 없이 완료되었습니다." : combined
        }.value
    }

    private func sanitizedShellCommand(_ command: String) -> String {
        command
            .replacingOccurrences(
                of: #"(?<![A-Za-z0-9_])status=\$\?"#,
                with: "exit_code=$?",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"\$status\b"#,
                with: "$exit_code",
                options: .regularExpression
            )
    }

    private func environmentWithCLIPaths() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        var paths = [
            home.appending(path: ".local/bin").path,
            home.appending(path: ".nvm/current/bin").path,
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/usr/local/bin",
            "/usr/local/sbin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ]

        let nvmVersions = home.appending(path: ".nvm/versions/node", directoryHint: .isDirectory)
        if let versions = try? fileManager.contentsOfDirectory(
            at: nvmVersions,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            let nodeBins = versions
                .filter { url in
                    ((try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false)
                }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedDescending }
                .map { $0.appending(path: "bin").path }
            paths.insert(contentsOf: nodeBins, at: 0)
        }

        let existingPath = environment["PATH"] ?? ""
        let combined = (paths + existingPath.split(separator: ":").map(String.init))
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, path in
                if !result.contains(path) {
                    result.append(path)
                }
            }
            .joined(separator: ":")
        environment["PATH"] = combined
        return environment
    }
}
