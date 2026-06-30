import Foundation

enum AIOutputCleaner {
    static func clean(_ output: String) -> String {
        var text = output
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(
                of: "\u{001B}\\[[0-9;]*[A-Za-z]",
                with: "",
                options: .regularExpression
            )

        if let report = bestReportCandidate(in: text) {
            text = report
        }

        text = text
            .replacingOccurrences(
                of: #"\[([^\]]+)\]\(https?://[^\)]+\)"#,
                with: "$1",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"https?://\S+"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"(?m)^(OpenAI Codex|workdir:|model:|provider:|approval:|sandbox:|reasoning|session id:|tokens used).*$"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return text.isEmpty ? output.trimmingCharacters(in: .whitespacesAndNewlines) : text
    }

    private static func bestReportCandidate(in text: String) -> String? {
        let headings = ["요약", "주요 위험", "손절/익절 점검", "더 안전한 조건 제안"]
        let starts = ranges(of: "요약", in: text).map(\.lowerBound)
        guard !starts.isEmpty else {
            return nil
        }

        var best: (score: Int, length: Int, text: String)?
        for start in starts {
            let suffix = String(text[start...])
            let candidate = truncateNoise(from: suffix)
            let score = headings.reduce(0) { partialResult, heading in
                partialResult + (candidate.contains(heading) ? 1 : 0)
            }
            guard score >= 2 else {
                continue
            }

            let current = (score: score, length: candidate.count, text: candidate)
            if let existing = best {
                if current.score > existing.score || (current.score == existing.score && current.length < existing.length) {
                    best = current
                }
            } else {
                best = current
            }
        }

        return best?.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func truncateNoise(from text: String) -> String {
        let markers = [
            "OpenAI Codex v",
            "\nworkdir:",
            "\nmodel:",
            "\nprovider:",
            "\napproval:",
            "\nsandbox:",
            "\nsession id:",
            "\nuser 당신",
            "\nuser ",
            "\ncodex ",
            "\ntokens used",
            "tokens used"
        ]

        let end = markers
            .compactMap { marker -> String.Index? in
                guard let index = text.range(of: marker)?.lowerBound else {
                    return nil
                }
                return text.distance(from: text.startIndex, to: index) > 20 ? index : nil
            }
            .min()

        if let end {
            return String(text[..<end])
        }
        return text
    }

    private static func ranges(of needle: String, in text: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: needle, range: searchRange) {
            ranges.append(range)
            searchRange = range.upperBound..<text.endIndex
        }
        return ranges
    }
}
