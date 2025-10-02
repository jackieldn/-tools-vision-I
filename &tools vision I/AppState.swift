import Foundation
import SwiftUI
import AVFoundation
import AndtoolsCore
import Combine

@MainActor
final class AppState: ObservableObject {
    // Data / selection
    @Published var batch = BatchManager()
    @Published var selectedItem: BatchItem?
    @Published var selectedFrameIndex: Int = 0

    // Player state
    @Published var player: AVPlayer?
    @Published var videoDuration: Double = 0
    @Published var videoSize: CGSize = .zero
    @Published var detectedFPS: Double = 25
    @Published var currentTime: Double = 0

    private var timeObserver: Any?

    func selectFirstIfNeeded() {
        if selectedItem == nil { selectedItem = batch.items.first }
    }

    func preparePlayer(for item: BatchItem?) {
        if let obs = timeObserver, let p = player { p.removeTimeObserver(obs) }
        timeObserver = nil
        player = nil
        videoDuration = 0
        videoSize = .zero
        detectedFPS = 25
        currentTime = 0

        guard let url = item?.url else { return }

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let p = AVPlayer(playerItem: playerItem)
        p.actionAtItemEnd = .pause
        player = p

        Task {
            async let dTime: CMTime = (try? await asset.load(.duration)) ?? .zero
            async let tracks = (try? await asset.loadTracks(withMediaType: .video)) ?? []
            let first = await tracks.first
            async let nat: CGSize = (try? await first?.load(.naturalSize)) ?? .zero
            async let t: CGAffineTransform = (try? await first?.load(.preferredTransform)) ?? .identity
            async let fpsF: Float = (try? await first?.load(.nominalFrameRate)) ?? 0

            let duration = await dTime
            let natural  = await nat
            let prefT    = await t
            let fps      = await fpsF

            let rect = CGRect(origin: .zero, size: natural).applying(prefT)
            let presented = CGSize(width: abs(rect.width), height: abs(rect.height))

            self.videoDuration = CMTimeGetSeconds(duration)
            self.videoSize     = presented == .zero ? natural : presented
            self.detectedFPS   = fps > 0 ? Double(fps) : 25.0

            installTimeObserver()
        }
    }

    private func installTimeObserver() {
        guard let p = player else { return }
        if let obs = timeObserver { p.removeTimeObserver(obs) }

        let hz = max(60, Int32(detectedFPS.rounded()))
        let interval = CMTime(value: 1, timescale: hz)

        timeObserver = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] t in
            guard let self else { return }
            self.currentTime = CMTimeGetSeconds(t)

            if let item = self.selectedItem, self.videoDuration > 0, !item.frames.isEmpty {
                let ratio = max(0, min(self.currentTime / self.videoDuration, 1))
                self.selectedFrameIndex = Int(round(ratio * Double(item.frames.count - 1)))
            }
        }
    }

    // Transport
    func togglePlay() {
        guard let p = player else { return }
        if p.timeControlStatus == .playing { p.pause() } else { p.play() }
    }

    func stop() { player?.pause(); player?.seek(to: .zero); currentTime = 0 }

    func step(by delta: Int) {
        guard let p = player else { return }
        let dt = max(1.0 / max(detectedFPS, 1), 0.001)
        let newT = max(0, min((currentTime + dt * Double(delta)), videoDuration))
        p.seek(to: CMTime(seconds: newT, preferredTimescale: 600))
    }

    func seekToRatio(_ r: Double) {
        guard let p = player, videoDuration > 0 else { return }
        let clamped = max(0, min(r, 1))
        p.seek(to: CMTime(seconds: clamped * videoDuration, preferredTimescale: 600))
    }
}
