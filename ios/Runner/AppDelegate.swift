import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerMethodChannels()
    return didFinish
  }

  private func registerMethodChannels() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let messenger = controller.binaryMessenger
    HttpMethodChannelHandler().register(with: messenger)
    PlatformMethodChannelHandler().register(with: messenger)
  }
}
