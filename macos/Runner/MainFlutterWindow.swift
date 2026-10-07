import Cocoa
import FlutterMacOS
import macos_window_utils

class MainFlutterWindow: NSWindow {
  /// Меньше этого интерфейс не помещается (см. MinSize в home_page.dart).
  private let minimumSize = NSSize(width: 1080, height: 680)

  override func awakeFromNib() {
    // Контроллер macos_window_utils даёт прозрачный заголовок и тёмное
    // оформление окна.
    let macOSWindowUtilsViewController = MacOSWindowUtilsViewController()
    self.contentViewController = macOSWindowUtilsViewController
    self.setContentSize(NSSize(width: 1440, height: 900))
    self.center()

    MainFlutterWindowManipulator.start(mainFlutterWindow: self)

    // После настройки окна: содержимое теперь на всю рамку, поэтому
    // ограничиваем и рамку, и содержимое — иначе при резком изменении
    // размера окно на мгновение становится меньше минимума.
    self.contentMinSize = minimumSize
    self.minSize = minimumSize

    RegisterGeneratedPlugins(registry: macOSWindowUtilsViewController.flutterViewController)

    super.awakeFromNib()
  }
}
