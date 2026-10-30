//
//  ReplayViewModel.swift
//  StrumMeng
//
//  Created by Sharon Tan on 29/10/26.
//

import Foundation
import Observation

/// ViewModel untuk mengatur jalannya layar Replay (US4).
///
/// Tugas utama ViewModel ini:
/// 1. Memutar ulang sesi latihan yang tersimpan dari `[BeatEvent]` di `SessionResult`.
/// 2. Menjaga waktu pemutaran (`songTime`) secara akurat tanpa bergantung pada audio mic atau controller input.
/// 3. Memunculkan feedback warna panah (`.perfect`, `.tooEarly`, `.miss`) pada node yang tepat di waktu yang tepat
///    tanpa melakukan penilaian ulang (*no re-judging*).
@MainActor
@Observable
final class ReplayViewModel {

    // MARK: - State & Data Sesi

    /// Status layar saat ini (misal: .ready, .playing, .paused, .finished, .dismissed).
    /// Menggunakan `private(set)` agar hanya bisa diubah melalui fungsi `send(_:)`.
    private(set) var state: ReplayState = .ready

    /// Hasil sesi latihan yang sedang diputar ulang (berisi rekaman BeatEvent, akurasi, dsb).
    let result: SessionResult

    /// Pola strumming gitar yang dimainkan (misal: "Foundation Strum").
    let pattern: StrumPattern

    /// Kecepatan tempo sesi latihan dalam Beat Per Minute (misal: 80 BPM).
    let bpm: Int

    /// Jarak waktu (detik) antar slot/subdivisi ketukan (misal: pada 80 BPM, 1/8 note = 0.375s).
    let stepInterval: TimeInterval

    /// Total jumlah step ketukan sepanjang sesi latihan.
    let totalSteps: Int

    /// Total durasi waktu seluruh sesi dalam detik (`totalSteps * stepInterval`).
    let duration: TimeInterval

    // MARK: - Manajemen Waktu & Animasi (Private)

    /// Titik waktu awal pemutaran (bernilai negatif sebagai lead-in agar panah muncul dari kanan sebelum beat 0).
    private let initialSongTime: TimeInterval

    /// Waktu lagu saat pemutaran dijeda (paused) atau saat sebelum mulai play.
    private var currentSongTime: TimeInterval

    /// Patokan posisi waktu lagu saat tombol Play ditekan/dilanjutkan.
    private var songTimeAtAnchor: TimeInterval = 0

    /// Waktu jam sistem (host uptime) saat tombol Play ditekan, digunakan untuk menghitung selisih waktu berjalan.
    private var hostTimeAnchor: TimeInterval?

    /// Daftar seluruh node panah di sepanjang rel lagu (dibuat dari pola stroke pattern).
    private let laneNodes: [PlayLaneNode]

    /// Closure untuk mendapatkan waktu sistem saat ini. Diinjeksi agar pengetesan (Unit Test) bisa berjalan deterministik.
    private let now: () -> TimeInterval

    /// Callback yang dipanggil saat user keluar dari layar Replay untuk kembali ke Summary.
    private let onDismiss: () -> Void

    // MARK: - Inisialisasi

    /// Membuat instance ReplayViewModel baru.
    /// - Parameters:
    ///   - result: Objek `SessionResult` dari sesi yang baru saja selesai dimainkan.
    ///   - pattern: Pola ketukan gitar (jika nil, otomatis dicari dari katalog berdasarkan `result.patternID`).
    ///   - repetitions: Berapa kali pola diulang (default 10 kali sesuai `PracticeSessionConfig`).
    ///   - now: Penyedia waktu jam sistem (default: `ProcessInfo.processInfo.systemUptime`).
    ///   - onDismiss: Callback navigasi kembali ke SummaryView saat tombol Back ditekan.
    init(
        result: SessionResult,
        pattern: StrumPattern? = nil,
        repetitions: Int? = nil,
        now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        onDismiss: @escaping () -> Void = {}
    ) {
        self.result = result
        let resolvedPattern = pattern ?? PatternCatalog.pattern(forID: result.patternID) ?? PatternCatalog.foundation
        self.pattern = resolvedPattern
        self.bpm = result.bpm
        self.now = now
        self.onDismiss = onDismiss

        // 1. Hitung interval waktu per slot ketukan berdasarkan BPM
        let reps = repetitions ?? PracticeSessionConfig.patternRepetitions
        let interval = PlayTimeline.slotInterval(bpm: result.bpm)
        self.stepInterval = interval

        // 2. Tentukan total langkah (memastikan cukup untuk menampung event terakhir yang tersimpan)
        let patternSteps = resolvedPattern.strokes.count * max(1, reps)
        let maxEventStep = (result.beatEvents.map(\.stepIndex).max() ?? 0) + 1
        let steps = max(patternSteps, maxEventStep)
        self.totalSteps = steps
        self.duration = Double(steps) * interval

        // 3. Pasang lead-in waktu awal di minus beberapa beat agar panah terlihat meluncur dari kanan
        self.initialSongTime = -PlayTimeline.readyLeadSlots * interval
        self.currentSongTime = self.initialSongTime

        // 4. Generate daftar visual panah (BeatNodeView) sepanjang rel trek
        self.laneNodes = PlayTimeline.makeNodes(
            pattern: resolvedPattern.strokes.map(Self.arrow(for:)),
            slotInterval: interval,
            duration: self.duration
        )
    }

    // MARK: - Properti Komputasi untuk UI

    /// Menandakan apakah animasi rel panah harus bergerak (hanya saat status `.playing`).
    var isAnimating: Bool {
        state == .playing
    }

    /// Nilai persentase progres sesi (0.0 sampai 1.0) untuk progress bar.
    var progress: Double {
        PlayTimeline.progress(songTime: songTime(), duration: duration)
    }

    /// Label format menit:detik waktu berjalan dan total (contoh: "00:15 / 01:00").
    var clockLabel: String {
        PlayTimeline.clockLabel(songTime: songTime(), duration: duration)
    }

    // MARK: - Pengendali Event (User Actions)

    /// Menerima dan memproses aksi pengguna (misal: tombol play, pause, restart, back).
    /// Mengalirkan event ke fungsi murni `reduce(state, event)` untuk menentukan state baru.
    func send(_ event: ReplayEvent) {
        let previous = state
        state = reduce(previous, event)
        guard state != previous || event == .restart else { return }

        switch (previous, state) {
        case (_, .playing):
            // Memulai atau melanjutkan pemutaran: rekam jangkar waktu sistem sekarang
            if previous == .finished || event == .restart {
                songTimeAtAnchor = initialSongTime
                currentSongTime = initialSongTime
            } else {
                songTimeAtAnchor = currentSongTime
            }
            hostTimeAnchor = now()

        case (_, .paused):
            // Menghentikan pemutaran sementara: bekukan waktu lagu
            currentSongTime = songTime()
            hostTimeAnchor = nil

        case (_, .finished):
            // Pemutaran selesai: kunci waktu lagu di durasi maksimal dan otomatis kembali ke summary
            currentSongTime = duration
            hostTimeAnchor = nil
            onDismiss()

        case (_, .dismissed):
            // Keluar dari replay: hentikan timer dan panggil aksi dismiss
            hostTimeAnchor = nil
            onDismiss()

        default:
            break
        }
    }

    // MARK: - Logika Waktu Playback

    /// Mengembalikan posisi waktu lagu saat ini (dalam detik, di mana 0 adalah ketukan pertama).
    /// Jika `hostTimeAnchor` aktif (sedang berjalan), waktu dihitung secara dinamis dari selisih `now() - hostTimeAnchor`.
    func songTime() -> TimeInterval {
        if let hostTimeAnchor {
            let elapsed = now() - hostTimeAnchor
            let calculated = songTimeAtAnchor + elapsed
            if calculated >= duration {
                return duration
            }
            return calculated
        }
        return currentSongTime
    }

    /// Memajukan waktu secara manual sejumlah detik tertentu (berguna terutama saat Unit Testing).
    func advanceTime(by seconds: TimeInterval) {
        guard seconds > 0 else { return }
        let target = songTime() + seconds
        if target >= duration {
            currentSongTime = duration
            send(.finish)
        } else {
            currentSongTime = target
            songTimeAtAnchor = target
            if hostTimeAnchor != nil {
                hostTimeAnchor = now()
            }
        }
    }

    // MARK: - Penyedia Data Tampilan (Screen Model)

    /// Menghasilkan representasi snapshot frame layar untuk dirender oleh SwiftUI View.
    ///
    /// Fungsi ini mencocokkan waktu lagu (`time`) dengan waktu tiap `BeatEvent`:
    /// - Node panah yang waktunya sudah terlewati otomatis diberi warna judgement yang tersimpan.
    /// - Menghitung animasi gelombang/lingkaran hit (`lastJudgement` & `lastStrumTime`).
    func screenModel() -> PlayScreenModel {
        let time = songTime()
        if state == .playing && time >= duration {
            send(.finish)
        }

        var nodes = laneNodes
        var lastJudgement: PlayJudgement?
        var lastStrumTime: TimeInterval?

        // Iterasi seluruh BeatEvent tersimpan untuk mewarnai node panah yang sudah lewat
        for event in result.beatEvents where nodes.indices.contains(event.stepIndex) {
            let nodeTime = Double(event.stepIndex) * stepInterval
            if time >= nodeTime {
                let judgement = PlayJudgement(
                    feedback: PlayFeedback(event.result),
                    time: nodeTime
                )
                nodes[event.stepIndex].judgement = judgement
                if nodeTime > (lastJudgement?.time ?? -.infinity) {
                    lastJudgement = judgement
                }
            }

            // Jika pada sesi asli user melakukan strumming, catat waktu strum-nya untuk efek pulsa ring
            if let offsetMs = event.offsetMs {
                let strumTime = nodeTime + (offsetMs / 1000.0)
                if time >= strumTime {
                    if strumTime > (lastStrumTime ?? -.infinity) {
                        lastStrumTime = strumTime
                    }
                }
            }
        }

        // Tentukan fase tampilan UI berdasarkan status state machine
        let phase: PlayScreenPhase = {
            switch state {
            case .ready: return .ready
            case .playing: return .playing
            case .paused: return .paused
            case .finished: return .playing
            case .dismissed: return .playing
            }
        }()

        return PlayScreenModel(
            title: pattern.name,
            bpm: bpm,
            duration: duration,
            slotInterval: stepInterval,
            songTime: time,
            phase: phase,
            nodes: nodes,
            lastJudgement: lastJudgement,
            lastStrumTime: lastStrumTime
        )
    }

    // MARK: - Helper

    /// Mengonversi nilai stroke model gitar (`.down`, `.up`, `.rest`) ke visual panah (`BeatNodeView.Arrow`).
    private static func arrow(for stroke: Stroke) -> BeatNodeView.Arrow? {
        switch stroke {
        case .down: return .down
        case .up: return .up
        case .rest: return nil
        }
    }
}
