import Flutter
import LocalAuthentication
import UIKit

final class PlatformMethodChannelHandler: NSObject {
    static let channelName = "com.liar.han1meplus/platform"
    private var authenticationResult: FlutterResult?

    func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler(handle)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setScreenBrightness":
            let value = (call.arguments as? [String: Any])?["value"] as? Double ?? 1
            DispatchQueue.main.async {
                UIScreen.main.brightness = CGFloat(min(max(value, 0.01), 1))
                result(nil)
            }

        case "screenBrightness":
            result(Double(UIScreen.main.brightness))

        case "volume":
            result(VolumeEmergencyHandler.shared.currentVolume())

        case "setVolume":
            let value = (call.arguments as? [String: Any])?["value"] as? Double ?? 1
            VolumeEmergencyHandler.shared.setVolume(value)
            result(nil)

        case "setHideFromRecents":
            let value = (call.arguments as? [String: Any])?["value"] as? Bool ?? false
            PrivacyOverlayManager.shared.setEnabled(value)
            result(nil)

        case "setEmergencyExit":
            let value = (call.arguments as? [String: Any])?["value"] as? Bool ?? false
            VolumeEmergencyHandler.shared.setEmergencyExitEnabled(value)
            result(nil)

        case "openAppLinksSettings":
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                result(FlutterError(code: "settings_unavailable", message: "Settings URL unavailable", details: nil))
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:]) { success in
                    result(success ? nil : FlutterError(code: "settings_failed", message: "Unable to open settings", details: nil))
                }
            }

        case "authenticate":
            authenticate(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func authenticate(result: @escaping FlutterResult) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            result(false)
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Han1me+") { success, _ in
            DispatchQueue.main.async { result(success) }
        }
    }
}
