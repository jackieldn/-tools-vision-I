import SwiftUI
import Combine
import AVFoundation
import AndtoolsCore

@main
struct AndtoolsVisionApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    appState.selectFirstIfNeeded()
                    appState.preparePlayer(for: appState.selectedItem)
                }
                // Observe the selected item's ID (UUID?) instead of the object itself
                .onChange(of: appState.selectedItem?.id) { _ in
                    appState.preparePlayer(for: appState.selectedItem)
                }
        }
        .windowResizability(.contentSize)
    }
}
