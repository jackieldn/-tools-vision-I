import SwiftUI
import AVFoundation

/// A minimal NSViewRepresentable that hosts an AVPlayerLayer (.resizeAspect).
struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer

    final class PlayerHostView: NSView {
        let playerLayer = AVPlayerLayer()

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer = playerLayer
            playerLayer.videoGravity = .resizeAspect
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        var player: AVPlayer? {
            get { playerLayer.player }
            set { playerLayer.player = newValue }
        }
    }

    func makeNSView(context: Context) -> PlayerHostView {
        let v = PlayerHostView()
        v.player = player
        return v
    }

    func updateNSView(_ nsView: PlayerHostView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
        nsView.playerLayer.videoGravity = .resizeAspect
    }
}
