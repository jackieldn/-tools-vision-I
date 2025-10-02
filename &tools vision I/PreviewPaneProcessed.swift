import SwiftUI
import AndtoolsCore
import CoreFoundation
import CoreGraphics
import AppKit

/// Shows the **processed downscaled frame** and draws overlays in the same pixel space.
/// This guarantees perfect alignment with OCR/analysis results.
struct PreviewPaneProcessed: View {
    @EnvironmentObject private var app: AppState

    private var currentFrame: FramePreview? {
        guard let item = app.selectedItem,
              app.selectedFrameIndex >= 0,
              app.selectedFrameIndex < item.frames.count else { return nil }
        return item.frames[app.selectedFrameIndex]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let frame = currentFrame {
                    // Base image aspect-fitted to the available size
                    let imgSize = imagePixelSize(from: frame.image)
                    let fit = aspectFitSize(image: imgSize, in: geo.size)
                    let origin = CGPoint(
                        x: (geo.size.width  - fit.width)  / 2,
                        y: (geo.size.height - fit.height) / 2
                    )

                    // Image
                    Image(nsImage: toNSImage(frame.image))
                        .resizable()
                        .interpolation(.high)
                        .frame(width: fit.width, height: fit.height)
                        .position(x: origin.x + fit.width/2,
                                  y: origin.y + fit.height/2)

                    // Overlays mapped from image pixels -> view points
                    overlayLayer(
                        frame: frame,
                        imagePixelSize: imgSize,
                        fitSize: fit,
                        fitOrigin: origin
                    )
                } else {
                    Text("Drop a video and run analysis to preview")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity,
                               maxHeight: .infinity)
                }
            }
        }
        .frame(minHeight: 360)
    }

    // MARK: - Overlay drawing

    @ViewBuilder
    private func overlayLayer(
        frame: FramePreview,
        imagePixelSize: CGSize,
        fitSize: CGSize,
        fitOrigin: CGPoint
    ) -> some View {
        // Scale from pixel space -> fitted view space
        let sx = fitSize.width  / imagePixelSize.width
        let sy = fitSize.height / imagePixelSize.height

        ZStack(alignment: .topLeading) {
            ForEach(frame.overlays, id: \.id) { ov in
                // overlay rects are in the processed-image pixel space (top-left origin)
                let r = ov.rect
                let x = fitOrigin.x + r.origin.x * sx
                let y = fitOrigin.y + r.origin.y * sy
                let w = r.size.width  * sx
                let h = r.size.height * sy

                Rectangle()
                    .stroke(borderColor(for: ov.status), lineWidth: 2)
                    .background(borderColor(for: ov.status).opacity(0.12))
                    .frame(width: w, height: h)
                    .position(x: x + w/2, y: y + h/2)

                // draw label if present
                let label = ov.text
                if !label.isEmpty {
                    Text(label)
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
    }

    private func borderColor(for status: OverlayStatus) -> Color {
        switch status {
        case .pass: return .green
        case .warn: return .yellow
        case .fail: return .red
        default:    return .gray
        }
    }

    // MARK: - Helpers

    private func aspectFitSize(image: CGSize, in container: CGSize) -> CGSize {
        guard image.width > 0, image.height > 0,
              container.width > 0, container.height > 0 else { return .zero }
        let s = min(container.width / image.width,
                    container.height / image.height)
        return CGSize(width: image.width * s,
                      height: image.height * s)
    }

    // ---- CF-safe CGImage extractor ----
    private func cgImage(from any: Any) -> CGImage? {
        guard let obj = any as AnyObject? else { return nil }
        if CFGetTypeID(obj) == CGImage.typeID {
            return (obj as! CGImage)
        }
        return nil
    }

    /// Size of FramePreview.image (NSImage or CGImage)
    private func imagePixelSize(from anyImage: Any) -> CGSize {
        if let ns = anyImage as? NSImage {
            return ns.size
        }
        if let cg = cgImage(from: anyImage) {
            return CGSize(width: cg.width, height: cg.height)
        }
        return .zero
    }

    /// Convert to NSImage for rendering
    private func toNSImage(_ img: Any) -> NSImage {
        if let ns = img as? NSImage { return ns }
        if let cg = cgImage(from: img) {
            let size = CGSize(width: cg.width, height: cg.height)
            let ns = NSImage(size: size)
            ns.addRepresentation(NSBitmapImageRep(cgImage: cg))
            return ns
        }
        return NSImage(size: .zero)
    }
}
