import SwiftUI
import AndtoolsCore
import AVFoundation

/// Plays the **full video** with AVPlayer and draws analysis overlays on top.
/// Overlays “stick” (persist) until the next analysed frame.
struct PreviewPane: View {
    @EnvironmentObject private var app: AppState

    // The frame we should draw overlays for (based on AppState.selectedFrameIndex)
    private var currentOverlayFrame: FramePreview? {
        guard let item = app.selectedItem else { return nil }
        let idx = min(max(app.selectedFrameIndex, 0), max(item.frames.count - 1, 0))
        return item.frames.isEmpty ? nil : item.frames[idx]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // 1) Base video (full smooth playback)
                if let p = app.player {
                    VideoPlayerView(player: p)
                        .clipped()
                        .overlay(alignment: .topLeading) {
                            // 2) Sticky overlays drawn on top of the video
                            if let frame = currentOverlayFrame, app.videoPresentationSize != .zero {
                                overlays(for: frame,
                                         videoPresentationSize: app.videoPresentationSize,
                                         in: aspectFitSize(image: app.videoPresentationSize, in: geo.size),
                                         viewOrigin: originForFit(fit: aspectFitSize(image: app.videoPresentationSize, in: geo.size),
                                                                  container: geo.size))
                            }
                        }
                } else {
                    Text("Drop a video and run analysis to preview")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minHeight: 360)
    }

    // MARK: - Overlay drawing (processed pixels -> video presentation -> aspect-fit view)

    // MARK: - Overlay drawing (processed pixels -> video presentation -> aspect-fit view)
    @ViewBuilder
    private func overlays(
        for frame: FramePreview,
        videoPresentationSize: CGSize,
        in fittedSize: CGSize,
        viewOrigin origin: CGPoint
    ) -> some View {

        // processed (analysis) image pixel size
        let processedSize = imagePixelSize(from: frame.image)

        if processedSize != .zero &&
           videoPresentationSize != .zero &&
           fittedSize != .zero {

            // processed -> presentation scale
            let kx = videoPresentationSize.width  / processedSize.width
            let ky = videoPresentationSize.height / processedSize.height

            // presentation -> aspect-fitted view scale
            let sx = fittedSize.width  / videoPresentationSize.width
            let sy = fittedSize.height / videoPresentationSize.height

            ZStack(alignment: .topLeading) {
                ForEach(frame.overlays, id: \.id) { ov in
                    let r  = ov.rect
                    let px = r.origin.x * kx,  py = r.origin.y * ky
                    let pw = r.size.width * kx, ph = r.size.height * ky

                    let x = origin.x + px * sx
                    let y = origin.y + py * sy
                    let w = pw * sx
                    let h = ph * sy

                    Rectangle()
                        .stroke(borderColor(for: ov.status), lineWidth: 2)
                        .background(borderColor(for: ov.status).opacity(0.12))
                        .frame(width: w, height: h)
                        .position(x: x + w/2, y: y + h/2)

                    if !ov.text.isEmpty {
                        Text(ov.text)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .position(x: x + w/2, y: max(0, y) - 10)
                    }
                }
            }

        } else {
            EmptyView()
        }
    }

    private func borderColor(for status: OverlayStatus) -> Color {
        switch status {
        case .pass: return .green
        case .warn: return .yellow
        case .fail: return .red
        default:    return .gray
        }
    }

    // MARK: - Layout helpers

    private func aspectFitSize(image: CGSize, in container: CGSize) -> CGSize {
        guard image.width > 0, image.height > 0,
              container.width > 0, container.height > 0 else { return .zero }
        let s = min(container.width / image.width, container.height / image.height)
        return CGSize(width: image.width * s, height: image.height * s)
    }

    private func originForFit(fit: CGSize, container: CGSize) -> CGPoint {
        CGPoint(x: (container.width  - fit.width)  / 2,
                y: (container.height - fit.height) / 2)
    }

    /// `FramePreview.image` may be `NSImage` or `CGImage`.
    private func imagePixelSize(from anyImage: Any) -> CGSize {
        if let ns = anyImage as? NSImage { return ns.size }  // stored as pixel-size already
        if let anyObj = anyImage as AnyObject?,
           CFGetTypeID(anyObj) == CGImage.typeID {
            let cg = anyObj as! CGImage
            return CGSize(width: cg.width, height: cg.height)
        }
        return .zero
    }
}
