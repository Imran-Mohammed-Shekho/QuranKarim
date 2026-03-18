import CoreLocation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let deviceCompassStreamHandler = DeviceCompassStreamHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    guard let registrar = self.registrar(forPlugin: "DeviceCompassStreamHandler") else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    let compassChannel = FlutterEventChannel(
      name: "quran/device_compass",
      binaryMessenger: registrar.messenger()
    )
    compassChannel.setStreamHandler(deviceCompassStreamHandler)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

final class DeviceCompassStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private var eventSink: FlutterEventSink?

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.headingFilter = 1
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard CLLocationManager.headingAvailable() else {
      return FlutterError(
        code: "NO_COMPASS_SENSOR",
        message: "Compass sensor is unavailable.",
        details: nil
      )
    }

    eventSink = events
    startHeadingUpdates()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stopHeadingUpdates()
    eventSink = nil
    return nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    eventSink?(heading)
  }

  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
    true
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      manager.startUpdatingHeading()
    case .denied, .restricted:
      eventSink?(
        FlutterError(
          code: "LOCATION_PERMISSION_DENIED",
          message: "Location permission is required for live compass heading.",
          details: nil
        )
      )
      stopHeadingUpdates()
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    @unknown default:
      eventSink?(
        FlutterError(
          code: "UNKNOWN_AUTHORIZATION",
          message: "Unknown location authorization state.",
          details: nil
        )
      )
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    eventSink?(
      FlutterError(
        code: "HEADING_ERROR",
        message: error.localizedDescription,
        details: nil
      )
    )
  }

  private func startHeadingUpdates() {
    switch locationManager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      locationManager.startUpdatingHeading()
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .denied, .restricted:
      eventSink?(
        FlutterError(
          code: "LOCATION_PERMISSION_DENIED",
          message: "Location permission is required for live compass heading.",
          details: nil
        )
      )
    @unknown default:
      eventSink?(
        FlutterError(
          code: "UNKNOWN_AUTHORIZATION",
          message: "Unknown location authorization state.",
          details: nil
        )
      )
    }
  }

  private func stopHeadingUpdates() {
    locationManager.stopUpdatingHeading()
  }
}
