import SwiftUI
import AndtoolsCore
import AVFoundation

struct TransportBar: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        HStack(spacing: 12) {
            Button { app.step(by: -1) } label: {
                Image(systemName: "backward.frame.fill")
            }.help("Step Back")

            Button { app.togglePlay() } label: {
                Image(systemName: app.player?.timeControlStatus == .playing ? "pause.fill" : "play.fill")
            }.help("Play / Pause")

            Button { app.step(by: +1) } label: {
                Image(systemName: "forward.frame.fill")
            }.help("Step Forward")

            Spacer()
            Text("\(Int(app.detectedFPS)) fps").foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}
