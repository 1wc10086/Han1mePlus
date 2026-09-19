import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private static let frameDefaultsKey = "mainWindowFrame"
  private var pendingFrame: NSRect?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    minSize = NSSize(width: 420, height: 300)
    // Load the Flutter view up front: its layout pass would otherwise resize
    // the window back to the storyboard frame after the restore below.
    _ = flutterViewController.view

    super.awakeFromNib()

    pendingFrame = loadSavedOrDefaultFrame()
    applyPendingFrame()
    observeFrameChanges()
  }

  private func loadSavedOrDefaultFrame() -> NSRect? {
    let saved = UserDefaults.standard.dictionary(forKey: Self.frameDefaultsKey) as? [String: Double]
    if let x = saved?["x"], let y = saved?["y"], let width = saved?["width"], let height = saved?["height"],
       width >= minSize.width, height >= minSize.height {
      let frame = NSRect(x: x, y: y, width: width, height: height)
      if NSScreen.screens.contains(where: { $0.visibleFrame.intersects(frame) }) {
        return frame
      }
    }
    return defaultFrame()
  }

  private func defaultFrame() -> NSRect? {
    guard let screen = NSScreen.screens.first else { return nil }
    var size = NSSize(width: 1280, height: 800)
    size.width = min(size.width, screen.visibleFrame.width)
    size.height = min(size.height, screen.visibleFrame.height)
    let origin = NSPoint(
      x: screen.visibleFrame.midX - size.width / 2,
      y: screen.visibleFrame.midY - size.height / 2
    )
    return NSRect(origin: origin, size: size)
  }

  private func applyPendingFrame() {
    guard let frame = pendingFrame else { return }
    setFrame(frame, display: true)
  }

  private func observeFrameChanges() {
    let center = NotificationCenter.default
    center.addObserver(self, selector: #selector(reapplyFrame), name: NSWindow.didBecomeKeyNotification, object: self)
    center.addObserver(self, selector: #selector(persistFrame(_:)), name: NSWindow.didEndLiveResizeNotification, object: self)
    center.addObserver(self, selector: #selector(persistFrame(_:)), name: NSWindow.didMoveNotification, object: self)
    center.addObserver(self, selector: #selector(persistFrame(_:)), name: NSWindow.willCloseNotification, object: self)
  }

  // The Flutter view layout can resize the window back to its storyboard frame
  // once the window becomes visible; reapply the restored frame once.
  @objc private func reapplyFrame() {
    guard !styleMask.contains(.fullScreen) else { return }
    applyPendingFrame()
    pendingFrame = nil
  }

  @objc private func persistFrame(_ notification: Notification?) {
    guard !styleMask.contains(.fullScreen) else { return }
    let frame = self.frame
    UserDefaults.standard.set(
      ["x": frame.origin.x, "y": frame.origin.y, "width": frame.width, "height": frame.height],
      forKey: Self.frameDefaultsKey
    )
  }
}
