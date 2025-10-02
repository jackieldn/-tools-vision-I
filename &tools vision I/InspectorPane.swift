import SwiftUI
import AndtoolsCore

struct InspectorPane: View {
    @ObservedObject var item: BatchItem
    @Binding var selectedIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Frame \(selectedIndex + 1) of \(item.frames.count)")
                    .font(.headline)
                Spacer()
                if let r = item.report {
                    HStack(spacing: 12) {
                        Label("\(r.passCount)", systemImage: "checkmark.circle").foregroundStyle(.green)
                        Label("\(r.warnCount)", systemImage: "exclamationmark.circle").foregroundStyle(.yellow)
                        Label("\(r.failCount)", systemImage: "xmark.octagon").foregroundStyle(.red)
                        Text("Time: \(r.processingTimeMs) ms").foregroundStyle(.secondary)
                    }.font(.caption)
                }
            }
            Divider()
            if let f = currentFrame {
                List(f.overlays) { ov in
                    HStack {
                        statusTag(ov.status)
                        Text(ov.text)
                        Spacer()
                        Text("x:\(Int(ov.rect.minX)) y:\(Int(ov.rect.minY)) w:\(Int(ov.rect.width)) h:\(Int(ov.rect.height))")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 180)
            } else {
                Text("No overlays.")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var currentFrame: FramePreview? {
        guard selectedIndex >= 0, selectedIndex < item.frames.count else { return nil }
        return item.frames[selectedIndex]
    }
    
    @ViewBuilder
    private func statusTag(_ s: OverlayStatus) -> some View {
        switch s {
        case .pass: Text("PASS").padding(4).background(.green.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 4))
        case .warn: Text("WARN").padding(4).background(.yellow.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 4))
        case .fail: Text("FAIL").padding(4).background(.red.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}
