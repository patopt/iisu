import Foundation
import Combine
import GameController

enum GamepadEvent: Equatable {
    case up, down, left, right
    /// Bottom face button by default; the top-row swap setting moves it to B.
    case confirm
    case back
    /// X / Y — used for the achievements panel, matching the Android build.
    case action
    /// Menu ("start") opens settings, Options ("select") opens quick settings.
    case menu
    case options
    case shoulderLeft, shoulderRight
}

/// Bridges MFi / DualSense / Xbox controllers into a simple event stream.
///
/// iiSU is controller-first on Android and stays so here. iOS surfaces
/// controllers through GameController; `GCSupportsControllerUserInteraction`
/// in Info.plist is what stops the system from also driving focus itself.
final class GamepadManager: ObservableObject {

    @Published private(set) var isConnected = false
    @Published private(set) var controllerName: String?

    let events = PassthroughSubject<GamepadEvent, Never>()

    /// Nintendo-style layout: confirm moves from A to B, action from X to Y.
    var swapConfirmButtons = false

    /// Directional input is analog and fires continuously; throttle it to a
    /// sane navigation cadence instead of one event per sampled frame.
    private let directionRepeatInterval: TimeInterval = 0.18
    private var lastDirectionAt: Date = .distantPast
    private var observers: [NSObjectProtocol] = []
    private var pressedButtons: Set<String> = []

    init() {
        let center = NotificationCenter.default
        observers.append(
            center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] note in
                guard let controller = note.object as? GCController else { return }
                self?.attach(controller)
            }
        )
        observers.append(
            center.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
                self?.refreshConnectionState()
            }
        )

        GCController.startWirelessControllerDiscovery(completionHandler: {})
        for controller in GCController.controllers() {
            attach(controller)
        }
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    private func attach(_ controller: GCController) {
        guard let gamepad = controller.extendedGamepad else { return }

        gamepad.valueChangedHandler = { [weak self] pad, _ in
            self?.handle(pad)
        }
        refreshConnectionState()
    }

    private func refreshConnectionState() {
        let controllers = GCController.controllers()
        DispatchQueue.main.async {
            self.isConnected = !controllers.isEmpty
            self.controllerName = controllers.first?.vendorName
        }
    }

    private func handle(_ pad: GCExtendedGamepad) {
        // Directions: d-pad and left stick both navigate.
        let horizontal = pad.dpad.xAxis.value + pad.leftThumbstick.xAxis.value
        let vertical = pad.dpad.yAxis.value + pad.leftThumbstick.yAxis.value
        let deadzone: Float = 0.5

        if abs(horizontal) > deadzone || abs(vertical) > deadzone {
            let now = Date()
            if now.timeIntervalSince(lastDirectionAt) >= directionRepeatInterval {
                lastDirectionAt = now
                if abs(horizontal) > abs(vertical) {
                    emit(horizontal > 0 ? .right : .left)
                } else {
                    emit(vertical > 0 ? .up : .down)
                }
            }
        } else {
            // Releasing the stick re-arms an immediate next step.
            lastDirectionAt = .distantPast
        }

        // Buttons: edge-triggered, so holding one does not repeat.
        edge("a", pad.buttonA.isPressed, swapConfirmButtons ? .back : .confirm)
        edge("b", pad.buttonB.isPressed, swapConfirmButtons ? .confirm : .back)
        edge("x", pad.buttonX.isPressed, .action)
        edge("y", pad.buttonY.isPressed, .action)
        edge("l", pad.leftShoulder.isPressed, .shoulderLeft)
        edge("r", pad.rightShoulder.isPressed, .shoulderRight)
        edge("menu", pad.buttonMenu.isPressed, .menu)
        if let options = pad.buttonOptions {
            edge("options", options.isPressed, .options)
        }
    }

    private func edge(_ key: String, _ isPressed: Bool, _ event: GamepadEvent) {
        if isPressed {
            guard !pressedButtons.contains(key) else { return }
            pressedButtons.insert(key)
            emit(event)
        } else {
            pressedButtons.remove(key)
        }
    }

    private func emit(_ event: GamepadEvent) {
        DispatchQueue.main.async {
            self.events.send(event)
        }
    }
}
