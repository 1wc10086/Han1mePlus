import UIKit

final class PrivacyOverlayManager {
    static let shared = PrivacyOverlayManager()

    private var enabled = false
    private var overlayWindow: UIWindow?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    func setEnabled(_ value: Bool) {
        enabled = value
        if !value { hideOverlay() }
    }

    @objc private func handleWillResignActive() {
        guard enabled else { return }
        showOverlay()
    }

    @objc private func handleDidBecomeActive() {
        hideOverlay()
    }

    private func showOverlay() {
        guard overlayWindow == nil else { return }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundInactive || $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .systemBackground
        let controller = UIViewController()
        controller.view.backgroundColor = .systemBackground
        let label = UILabel()
        label.text = "Han1me+"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
        ])
        window.rootViewController = controller
        window.isHidden = false
        overlayWindow = window
    }

    private func hideOverlay() {
        overlayWindow?.isHidden = true
        overlayWindow = nil
    }
}
