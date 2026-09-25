import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // تصفير عداد البادج عند بدء التشغيل لأول مرة (Cold Start)
    clearAppBadge(application)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // تصفير عداد البادج عند عودة التطبيق للواجهة من الخلفية (App Switcher)
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    clearAppBadge(application)
  }

  // دالة مساعدة تدعم الإصدارات الحديثة والقديمة من iOS
  private func clearAppBadge(_ application: UIApplication) {
    if #available(iOS 16.0, *) {
      UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    } else {
      application.applicationIconBadgeNumber = 0
    }
  }
}

```