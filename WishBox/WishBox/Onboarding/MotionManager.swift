import CoreMotion
import Combine

/// Publishes device roll and pitch from CMMotionManager for parallax effects.
final class MotionManager: ObservableObject {
    @Published var roll: Double = 0
    @Published var pitch: Double = 0

    private let manager = CMMotionManager()

    init() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.roll  = motion.attitude.roll
            self.pitch = motion.attitude.pitch
        }
    }

    deinit {
        manager.stopDeviceMotionUpdates()
    }
}
