import XCTest
@testable import StrumMeng

final class KarplusStrongTests: XCTestCase {
    private let sampleRate = 48_000.0

    private func pluck(midi: Int = 45, velocity: Double = 0.65, seed: UInt64 = 1) -> [Float] {
        var random = SeededRandom(seed: seed)
        return KarplusStrong.pluck(sampleRate: sampleRate, midi: midi, velocity: velocity,
                                   instrument: .nylon, sustain: 1.5, brightness: 0.5, random: &random)
    }

    /// The lag (in samples) where the signal best matches itself: one period of the note.
    private func period(of samples: [Float], from start: Int, minLag: Int, maxLag: Int) -> Int {
        let window = 4096
        var best = minLag
        var bestScore = -Float.infinity
        for lag in minLag...maxLag {
            var score: Float = 0
            for i in start..<(start + window) { score += samples[i] * samples[i + lag] }
            if score > bestScore { bestScore = score; best = lag }
        }
        return best
    }

    func test_noteLastsTheFixedLength() {
        XCTAssertEqual(pluck().count, Int(sampleRate * KarplusStrong.noteSeconds))
    }

    func test_noteIsAudible_andNeverClips() {
        let samples = pluck(velocity: 0.95)
        let peak = samples.map { abs($0) }.max() ?? 0
        XCTAssertGreaterThan(peak, 0.05)
        XCTAssertLessThanOrEqual(peak, 1)
    }

    func test_noteFadesToSilenceAtTheEnd() {
        XCTAssertEqual(pluck().last, 0)
    }

    func test_sameSeed_givesTheSameNote() {
        XCTAssertEqual(pluck(seed: 7), pluck(seed: 7))
        XCTAssertNotEqual(pluck(seed: 7), pluck(seed: 8))
    }

    func test_harderPluck_isLouder() {
        let soft = pluck(velocity: 0.35).map { abs($0) }.max() ?? 0
        let hard = pluck(velocity: 0.95).map { abs($0) }.max() ?? 0
        XCTAssertGreaterThan(hard, soft)
    }

    func test_openAString_isTunedTo110Hz() {
        // A2 = 110 Hz: one period is 48000 / 110 ≈ 436.4 samples.
        let samples = pluck(midi: 45)
        let lag = period(of: samples, from: 9600, minLag: 380, maxLag: 500)
        XCTAssertEqual(Double(lag), sampleRate / 110, accuracy: 1.5)
    }
}
