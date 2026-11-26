import Flutter
import ObjectiveC
import PhotosUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // image_picker's PHPicker presents as a sheet by default; force full screen.
    UIViewController.eh_enableFullScreenPhotoPickers()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

private extension UIViewController {
  static func eh_enableFullScreenPhotoPickers() {
    let original = class_getInstanceMethod(
      UIViewController.self,
      #selector(UIViewController.present(_:animated:completion:))
    )
    let swizzled = class_getInstanceMethod(
      UIViewController.self,
      #selector(UIViewController.eh_present(_:animated:completion:))
    )
    guard let original, let swizzled else { return }
    method_exchangeImplementations(original, swizzled)
  }

  @objc func eh_present(
    _ viewControllerToPresent: UIViewController,
    animated flag: Bool,
    completion: (() -> Void)? = nil
  ) {
    if #available(iOS 14.0, *), viewControllerToPresent is PHPickerViewController {
      viewControllerToPresent.modalPresentationStyle = .fullScreen
    }
    if viewControllerToPresent is UIImagePickerController {
      viewControllerToPresent.modalPresentationStyle = .fullScreen
    }
    // After exchange, this calls the original present(_:animated:completion:).
    eh_present(viewControllerToPresent, animated: flag, completion: completion)
  }
}
