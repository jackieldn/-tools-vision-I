import SwiftUI
import UniformTypeIdentifiers
import AndtoolsCore

struct ContentView: View {
    @EnvironmentObject private var app: AppState
    @State private var showImporter = false

    var body: some View {
        NavigationSplitView {
            BatchInspector()
                .frame(minWidth: 280)
        } detail: {
            VStack(spacing: 8) {
                if let item = app.selectedItem {
                    // Processed-preview player (guaranteed overlay alignment)
                    PreviewPaneProcessed()
                        .environmentObject(app)

                    // NLE-style scrubber + transport
                    TimelineViewAE(item: item, selectedIndex: $app.selectedFrameIndex)
                        .environmentObject(app)

                    // Text/box list inspector
                    InspectorPane(item: item, selectedIndex: $app.selectedFrameIndex)
                } else {
                    ContentPlaceholder()
                }
            }
            .padding(8)
        }
        .toolbar {
            ToolbarItemGroup {
                Button { showImporter = true } label: {
                    Label("Open", systemImage: "folder")
                }
                Button {
                    Task { await app.batch.runQuickSelected() }
                } label: { Label("Run Quick", systemImage: "play.circle") }
                Button {
                    Task { await app.batch.runExhaustiveSelected() }
                } label: { Label("Run Exhaustive", systemImage: "bolt.circle") }
                Button(role: .cancel) { app.batch.cancelAll() } label: {
                    Label("Cancel", systemImage: "stop.circle")
                }
                Button(role: .destructive) {
                    app.batch.cancelAll()
                    app.batch.clear()
                    app.selectedItem = nil
                } label: { Label("Clear", systemImage: "trash") }
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.movie],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task { @MainActor in
                    app.batch.add(urls: urls)
                    app.selectFirstIfNeeded()
                    app.preparePlayer(for: app.selectedItem)
                }
            case .failure(let err):
                print("Import failed: \(err)")
            }
        }
        .onDrop(of: [.movie], isTargeted: nil) { providers in
            Task {
                var urls: [URL] = []
                for p in providers {
                    if let url = try? await p.loadItem(
                        forTypeIdentifier: UTType.movie.identifier
                    ) as? URL {
                        urls.append(url)
                    }
                }
                await MainActor.run {
                    app.batch.add(urls: urls)
                    app.selectFirstIfNeeded()
                    app.preparePlayer(for: app.selectedItem)
                }
            }
            return true
        }
        // Keep metadata/player state updated when selection changes
        .onChange(of: app.selectedItem?.id) { _, _ in
            app.preparePlayer(for: app.selectedItem)
        }
    }
}

private struct ContentPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.dashed.badge.record")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Drop MP4s here or use Open")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
