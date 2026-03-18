import 'package:flutter/services.dart';

class DeviceCompassService {
  static const EventChannel _channel = EventChannel('quran/device_compass');

  Stream<double> headingStream() {
    return _channel.receiveBroadcastStream().map((dynamic event) {
      final value = event as num?;
      if (value == null) {
        throw PlatformException(
          code: 'INVALID_HEADING',
          message: 'Compass stream returned an empty heading.',
        );
      }
      return value.toDouble();
    });
  }
}
