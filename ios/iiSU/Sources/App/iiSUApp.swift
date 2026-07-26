import SwiftUI

@main
struct iiSUApp: App {

    @StateObject private var settings = AppSettings()
    @StateObject private var gamepad = GamepadManager()
    @StateObject private var updates = UpdateChecker()
    @StateObject private var achievements = RetroAchievementsClient()
    @StateObject private var library: LibraryStore

    private let catalogError: String?

    init() {
        do {
            let catalog = try EmulatorCatalog.loadBundled()
            _library = StateObject(wrappedValue: LibraryStore(catalog: catalog))
            catalogError = nil
        } catch {
            _library = StateObject(wrappedValue: LibraryStore(catalog: .empty))
            catalogError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(catalogError: catalogError)
                .environmentObject(settings)
                .environmentObject(gamepad)
                .environmentObject(updates)
                .environmentObject(achievements)
                .environmentObject(library)
                .preferredColorScheme(.dark)
                .tint(settings.accent.color)
        }
    }
}
