import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Open at a comfortable desktop size and never let the window shrink below
    // the app's desktop layout breakpoint (900pt), so the UI stays usable
    // instead of collapsing into the cramped mobile layout.
    self.setContentSize(NSSize(width: 1200, height: 820))
    self.contentMinSize = NSSize(width: 960, height: 660)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
