import SwiftUI
import AndtoolsCore

struct TimelineViewAE: View {
    @EnvironmentObject private var app: AppState
    @ObservedObject var item: BatchItem
    @Binding var selectedIndex: Int

    private let maxMarkers = 300
    @State private var isScrubbing = false

    var body: some View {
        VStack(spacing: 6) {
            TransportBar()

            GeometryReader { geo in
                ZStack {
                    Capsule()
                        .fill(Color.gray.opacity(0.18))
                        .frame(height: 18)

                    // Markers (sample if too many)
                    let count = item.frames.count
                    let indices: [Int] = {
                        guard count > 0 else { return [] }
                        if count <= maxMarkers { return Array(0..<count) }
                        let step = Double(count) / Double(maxMarkers)
                        return (0..<maxMarkers).map { Int(Double($0) * step) }
                    }()

                    ForEach(indices, id: \.self) { idx in
                        Rectangle()
                            .fill(color(for: frameSeverity(item.frames[idx])))
                            .frame(width: 2, height: 18)
                            .position(
                                x: xPos(for: idx, total: count, width: geo.size.width),
                                y: 9
                            )
                    }

                    // Playhead handle
                    let px = xPos(for: selectedIndex, total: count, width: geo.size.width)
                    ZStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 26)
                            .shadow(color: .black.opacity(0.4), radius: 2)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .offset(y: 13)
                            .shadow(radius: 1)
                    }
                    .position(x: px, y: 9)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isScrubbing = true
                            let x = max(0, min(value.location.x, geo.size.width))
                            let idx = index(forX: x, total: item.frames.count, width: geo.size.width)
                            selectedIndex = idx

                            // Seek the **video** to the matching ratio
                            if item.frames.count > 1 {
                                let ratio = Double(idx) / Double(item.frames.count - 1)
                                app.seekToRatio(ratio)
                            }
                        }
                        .onEnded { _ in
                            isScrubbing = false
                        }
                )
            }
            .frame(height: 44)
        }
    }

    // MARK: mapping
    private func xPos(for index: Int, total: Int, width: CGFloat) -> CGFloat {
        guard total > 1 else { return 0 }
        return CGFloat(index) / CGFloat(total - 1) * width
    }
    private func index(forX x: CGFloat, total: Int, width: CGFloat) -> Int {
        guard total > 1 else { return 0 }
        let ratio = max(0, min(x / max(width, 1), 1))
        return Int(round(ratio * CGFloat(total - 1)))
    }

    // MARK: severity coloring
    enum Severity { case none, pass, warn, fail }
    private func frameSeverity(_ f: FramePreview) -> Severity {
        if f.overlays.contains(where: { $0.status == .fail }) { return .fail }
        if f.overlays.contains(where: { $0.status == .warn }) { return .warn }
        if f.overlays.contains(where: { $0.status == .pass }) { return .pass }
        return .none
    }
    private func color(for s: Severity) -> Color {
        switch s {
        case .none: return .gray.opacity(0.25)
        case .pass: return .green
        case .warn: return .yellow
        case .fail: return .red
        }
    }
}
