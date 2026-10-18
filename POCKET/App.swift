import SwiftUI

@main struct PocketApp:App {
    @StateObject private var session=Session()
    @Environment(\.scenePhase) private var scenePhase
    var body:some Scene {
        WindowGroup {
            RootView(s:session)
                .preferredColorScheme(.dark)
                .onChange(of:scenePhase) { _,phase in if phase != .active { session.stop() } }
        }
    }
}
