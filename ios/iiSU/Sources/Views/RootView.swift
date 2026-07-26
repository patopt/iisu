import SwiftUI

struct RootView: View {
    let catalogError: String?

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var gamepad: GamepadManager

    var body: some View {
        Group {
            if let catalogError {
                CatalogFailureView(message: catalogError)
            } else if settings.hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        .task {
            await library.scan()
        }
        // Keep the controller mapping in step with the Nintendo-layout toggle.
        .onAppear { gamepad.swapConfirmButtons = settings.swapConfirmButtons }
        .onChange(of: settings.swapConfirmButtons) { newValue in
            gamepad.swapConfirmButtons = newValue
        }
    }
}

private struct CatalogFailureView: View {
    let message: String

    var body: some View {
        ZStack {
            BackgroundGradient()
            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.yellow)
                Text("iiSU could not start")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text(message)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 32)
            }
        }
    }
}
