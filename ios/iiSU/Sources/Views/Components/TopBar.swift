import SwiftUI
import UIKit

/// The status strip across the top of the frontend: identity on the left, the
/// current selection in the middle, clock/date/battery on the right — with the
/// shoulder-button tags the Android build shows above the outer pills.
struct TopBar: View {
    let title: String
    let subtitle: String?
    let libraryCount: Int

    @StateObject private var clock = ClockModel()

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            leftCluster
            Spacer(minLength: 8)
            centerPill
            Spacer(minLength: 8)
            rightCluster
        }
    }

    private var leftCluster: some View {
        VStack(alignment: .leading, spacing: 3) {
            ShoulderTag(text: "LT")
            GlassPill {
                HStack(spacing: 8) {
                    Wordmark(height: 15)
                    Text("\(libraryCount)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private var centerPill: some View {
        GlassPill {
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: 260)
        }
        .layoutPriority(1)
    }

    private var rightCluster: some View {
        VStack(alignment: .trailing, spacing: 3) {
            ShoulderTag(text: "RT")
            GlassPill {
                HStack(spacing: 7) {
                    Text(clock.time)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    separator
                    Text(clock.date)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .monospacedDigit()
                    separator
                    batteryIndicator
                }
                .foregroundColor(Theme.textPrimary)
            }
        }
    }

    private var separator: some View {
        Text("|")
            .font(.system(size: 11, weight: .light))
            .foregroundColor(Theme.textTertiary)
    }

    private var batteryIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: clock.batterySymbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(clock.batteryTint)
            Text(clock.batteryText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
    }
}

/// Drives the clock and battery readout.
///
/// A one-second timer would be wasted here — the bar shows minutes — so it
/// ticks on the minute boundary and on battery notifications instead.
final class ClockModel: ObservableObject {
    @Published private(set) var time: String = ""
    @Published private(set) var date: String = ""
    @Published private(set) var batteryLevel: Float = -1
    @Published private(set) var batteryState: UIDevice.BatteryState = .unknown

    private var timer: Timer?

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        refresh()

        timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.refresh() }
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func refresh() {
        let now = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        time = timeFormatter.string(from: now)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        date = dateFormatter.string(from: now)

        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
    }

    var batteryText: String {
        // The simulator and devices with monitoring unavailable report -1.
        guard batteryLevel >= 0 else { return "--%" }
        return "\(Int((batteryLevel * 100).rounded()))%"
    }

    var batterySymbol: String {
        switch batteryState {
        case .charging, .full:
            return "battery.100.bolt"
        default:
            guard batteryLevel >= 0 else { return "battery.50" }
            switch batteryLevel {
            case ..<0.15: return "battery.25"
            case ..<0.5: return "battery.50"
            default: return "battery.100"
            }
        }
    }

    var batteryTint: Color {
        switch batteryState {
        case .charging, .full:
            return Color(hex: 0x3FD9A0)
        default:
            return batteryLevel >= 0 && batteryLevel < 0.15 ? .red : Color(hex: 0x3FD9A0)
        }
    }
}
