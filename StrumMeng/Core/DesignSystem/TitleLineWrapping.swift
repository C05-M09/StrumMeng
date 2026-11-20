import Foundation

/// Explicit lines allow negative VStack spacing; Text.lineSpacing cannot tighten a font's leading.
enum TitleLineWrapping {
    /// Splits "... Strum" pattern titles so "STRUM" always sits on its own second line, matching Listen.
    static func patternLines(for title: String) -> [String] {
        title.uppercased()
            .replacingOccurrences(of: " STRUM", with: "\nSTRUM")
            .components(separatedBy: "\n")
    }

    /// Uses `patternLines` for "... Strum" titles and wraps other titles at `singleLineLimit`.
    static func headerLines(for title: String) -> [String] {
        if title.uppercased().contains(" STRUM") {
            return patternLines(for: title)
        }
        return lines(for: title)
    }

    static func lines(for title: String, singleLineLimit: Int = 22) -> [String] {
        let explicit = title.split(separator: "\n").map(String.init)
        if explicit.count > 1 { return explicit }
        let words = title.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard words.count > 1, title.count > singleLineLimit else { return [words.joined(separator: " ")] }
        let split = (1..<words.count).min { a, b in
            difference(words, at: a) < difference(words, at: b)
        } ?? 1
        return [words[..<split].joined(separator: " "), words[split...].joined(separator: " ")]
    }
    private static func difference(_ words: [String], at split: Int) -> Int {
        abs(words[..<split].joined(separator: " ").count - words[split...].joined(separator: " ").count)
    }
}
