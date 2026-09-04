import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class HomeViewModel {
    private(set) var phase: FocusSessionPhase = .idle
    private(set) var remainingSeconds: TimeInterval = FocusSessionConfig.defaultDuration
    private(set) var motionState: CompanionMotionState = .away
    private(set) var pendingGiftTitle: String?
    private(set) var showGiftReveal = false

    private var timerTask: Task<Void, Never>?
    private var didAttemptPoseBackfill = false

    var formattedRemainingTime: String {
        let total = max(0, Int(remainingSeconds))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var isFocusActive: Bool {
        phase == .running || phase == .paused
    }

    func startFocus(with companion: Companion) {
        guard phase == .idle || phase == .completed else { return }
        remainingSeconds = FocusSessionConfig.defaultDuration
        phase = .running
        motionState = .runningIn
        scheduleRunInToSit()
        startTimer(for: companion)
    }

    func pauseFocus() {
        guard phase == .running else { return }
        phase = .paused
        stopTimer()
    }

    func resumeFocus(with companion: Companion) {
        guard phase == .paused else { return }
        phase = .running
        startTimer(for: companion)
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
            try? await Task.sleep(nanoseconds: 1_200_000_000)
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

    func refreshCutoutIfNeeded(for companion: Companion) {
        backfillActionPosesIfNeeded(for: companion)

        guard CutoutImageProcessor.needsCutoutRefresh(companion.cutoutData),
              let portraitData = companion.comicPortraitData,
              let portrait = UIImage(data: portraitData) else {
            return
        }

        Task {
            let service = MattingService()
            if let refreshed = try? await service.extractCutout(from: portrait) {
                companion.cutoutData = refreshed
            }
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

    private func backfillActionPosesIfNeeded(for companion: Companion) {
        guard !didAttemptPoseBackfill else { return }
        guard !companion.poseCutouts.canFlipbook else { return }
        guard let portraitData = companion.comicPortraitData,
              let portrait = UIImage(data: portraitData) else {
            return
        }

        didAttemptPoseBackfill = true
        let style = companion.styleTemplate
        Task {
            let extras = await GenerationService().generateActionPoses(from: portrait, style: style)
            if companion.cutoutRunAData == nil {
                companion.cutoutRunAData = extras.runA
            }
            if companion.cutoutRunBData == nil {
                companion.cutoutRunBData = extras.runB
            }
            if companion.cutoutLandData == nil {
                companion.cutoutLandData = extras.land
            }
        }
    }
}
