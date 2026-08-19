import UIKit
import Flutter
import MessageUI

@main
@objc class AppDelegate: FlutterAppDelegate, MFMessageComposeViewControllerDelegate {
  private let smsComposeChannelName = "com.matzilon.mezilon/sms_compose"
  private var activeMessageComposer: MFMessageComposeViewController?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let flutterViewController = window?.rootViewController as? FlutterViewController {
      let smsComposeChannel = FlutterMethodChannel(
        name: smsComposeChannelName,
        binaryMessenger: flutterViewController.binaryMessenger
      )
      smsComposeChannel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "composeSms" else {
          result(FlutterMethodNotImplemented)
          return
        }

        guard let self = self else {
          result(false)
          return
        }
        self.composeSms(call, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func composeSms(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let number = arguments["number"] as? String,
      let body = arguments["body"] as? String,
      !number.isEmpty,
      MFMessageComposeViewController.canSendText(),
      activeMessageComposer == nil,
      let presenter = presentationViewController()
    else {
      result(false)
      return
    }

    DispatchQueue.main.async { [weak self] in
      guard
        let self = self,
        self.activeMessageComposer == nil,
        presenter.viewIfLoaded?.window != nil,
        !presenter.isBeingDismissed,
        !presenter.isBeingPresented
      else {
        result(false)
        return
      }

      let composer = MFMessageComposeViewController()
      composer.recipients = [number]
      composer.body = body
      composer.messageComposeDelegate = self
      self.activeMessageComposer = composer

      presenter.present(composer, animated: true) { [weak self, weak composer] in
        guard
          let self = self,
          let composer = composer,
          self.activeMessageComposer === composer
        else {
          return
        }
        result(true)
      }
    }
  }

  private func presentationViewController() -> UIViewController? {
    guard var presenter = window?.rootViewController else {
      return nil
    }

    while let presentedViewController = presenter.presentedViewController,
      !presentedViewController.isBeingDismissed {
      presenter = presentedViewController
    }
    return presenter
  }

  func messageComposeViewController(
    _ controller: MFMessageComposeViewController,
    didFinishWith _: MessageComposeResult
  ) {
    controller.dismiss(animated: true) { [weak self] in
      self?.activeMessageComposer = nil
    }
  }
}
