import Foundation
import SwiftUI
import SwiftData
import UIKit

@Observable
@MainActor
final class HomeViewModel {
    private(set) var phase: FocusSessionPhase = .idle
    private(set) var remainingSeconds: TimeInterval = FocusSessionConfig.defaultDuration
    private(set) var motionState: CompanionMotionState = .idle
    private(set) var pendingGiftTitle: String?
    private(set) var showGiftReveal = false

    private var timerTask: Task<Void, Never>?

    var formattedRemainingTime: String {
        let total = max(0, Int(remainingSeconds))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var isFocusActive: Bool {
        phase == .running
    }

    func startFocus(with companion: Companion) {
        guard phase == .idle || phase == .completed else { return }
        remainingSeconds = FocusSessionConfig.defaultDuration
        phase = .running
        // Briefly hide the seated dog so run-in can start from off-screen left.
        motionState = .away
        scheduleRunInToSit()
        startTimer(for: companion)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 16_000_000)
            guard phase == .running else { return }
            motionState = .runningIn
        }
    }

    func cancelFocus() {
        stopTimer()
        phase = .idle
        remainingSeconds = FocusSessionConfig.defaultDuration
        motionState = .away
    }

    func completeFocus(for companion: Companion) {
        stopTimer()
        phase = .completed
        motionState = .celebrating

        companion.completedFocusSessions += 1
        let unlocked = GiftUnlockPolicy.applyRewards(
            for: companion.completedFocusSessions,
            to: companion
        )
        pendingGiftTitle = GiftUnlockPolicy.giftTitle(
            for: companion.completedFocusSessions,
            unlockedItems: unlocked
        )
        showGiftReveal = true

        Task {
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            motionState = .idle
        }
    }

    func dismissGift() {
        showGiftReveal = false
        phase = .idle
        remainingSeconds = FocusSessionConfig.defaultDuration
        motionState = .away
    }

    func reactToTap() {
        guard motionState == .idle || motionState == .runningIn else { return }
        motionState = .reacting
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            if motionState == .reacting {
                motionState = .idle
            }
        }
    }

    func refreshCutoutIfNeeded(for companion: Companion) async {
        if let existing = companion.cutoutData {
            let opaque = CutoutImageProcessor.forceOpaqueCutout(from: existing)
            if !CutoutImageProcessor.needsCutoutRefresh(opaque) {
                if opaque != existing {
                    companion.cutoutData = opaque
                }
                return
            }
        }

        guard let portraitData = companion.comicPortraitData else {
            return
        }
        do {
            let chroma = try await Task.detached(priority: .userInitiated) {
                let cutout = try CutoutImageProcessor.chromaKeyCutout(fromPNG: portraitData)
                return CutoutImageProcessor.forceOpaqueCutout(from: cutout)
            }.value
            guard !CutoutImageProcessor.needsCutoutRefresh(chroma) else { return }
            companion.cutoutData = chroma
        } catch {
            return
        }
    }

    private func startTimer(for companion: Companion) {
        stopTimer()
        timerTask = Task {
            while !Task.isCancelled, remainingSeconds > 0 {
                try? await Task.sleep(nanoseconds: UInt64(FocusSessionConfig.tickInterval * 1_000_000_000))
                guard !Task.isCancelled else { return }
                if phase == .running {
                    remainingSeconds = max(0, remainingSeconds - FocusSessionConfig.tickInterval)
                    if remainingSeconds == 0 {
                        completeFocus(for: companion)
                        return
                    }
                }
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func scheduleRunInToSit() {
        Task {
            let nanos = UInt64((PosePlayback.runningInDuration + 0.08) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            if motionState == .runningIn {
                motionState = .idle
            }
        }
    }
}
