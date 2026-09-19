import AVFoundation
import MediaPlayer
import UIKit

final class VolumeEmergencyHandler {
    static let shared = VolumeEmergencyHandler()

    private var emergencyExitEnabled = false
    private var volumePresses = 0
    private var lastVolumePress = 0.0
    private var previousVolume = AVAudioSession.sharedInstance().outputVolume
    private var volumeView: MPVolumeView?
    private var volumeObservation: NSKeyValueObservation?

    private init() {
        try? AVAudioSession.sharedInstance().setActive(true)
        volumeObservation = AVAudioSession.sharedInstance().observe(\.outputVolume, options: [.new, .old]) { [weak self] session, _ in
            guard let self, self.emergencyExitEnabled else { return }
            let newValue = session.outputVolume
            let now = Date().timeIntervalSince1970
            if newValue > self.previousVolume || (newValue == self.previousVolume && newValue >= 0.99) {
                self.volumePresses = now - self.lastVolumePress < 1 ? self.volumePresses + 1 : 1
                self.lastVolumePress = now
                if self.volumePresses >= 3 {
                    self.volumePresses = 0
                    self.triggerEmergencyExit()
                }
            }
            self.previousVolume = newValue
        }
    }

    func setEmergencyExitEnabled(_ value: Bool) {
        emergencyExitEnabled = value
        if !value { volumePresses = 0 }
    }

    func currentVolume() -> Double {
        Double(AVAudioSession.sharedInstance().outputVolume)
    }

    func setVolume(_ value: Double) {
        DispatchQueue.main.async {
            let clamped = Float(min(max(value, 0), 1))
            if self.volumeView == nil {
                let view = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
                view.showsRouteButton = false
                view.alpha = 0.01
                self.topWindow()?.addSubview(view)
                self.volumeView = view
            }
            if let slider = self.volumeView?.subviews.compactMap({ $0 as? UISlider }).first {
                slider.value = clamped
            } else {
                MPVolumeView.setVolume(clamped)
            }
            self.previousVolume = clamped
        }
    }

    private func triggerEmergencyExit() {
        DispatchQueue.main.async {
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                exit(0)
            }
        }
    }

    private func topWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }
}

private extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let view = MPVolumeView(frame: .zero)
        if let slider = view.subviews.compactMap({ $0 as? UISlider }).first {
            slider.value = volume
        }
    }
}
