import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register the native rendering plugin
    if let registrar = self.registrar(forPlugin: "NativeRenderingPlugin") {
      NativeRenderingPlugin.register(with: registrar)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
