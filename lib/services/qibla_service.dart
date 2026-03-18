import 'dart:math' as math;

import '../models/prayer_time_model.dart';

class QiblaService {
  static const double _kaabaLatitude = 21.4225;
  static const double _kaabaLongitude = 39.8262;

  double qiblaBearing(DeviceLocation location) {
    final latitudeRadians = _toRadians(location.latitude);
    final longitudeRadians = _toRadians(location.longitude);
    final kaabaLatitudeRadians = _toRadians(_kaabaLatitude);
    final kaabaLongitudeRadians = _toRadians(_kaabaLongitude);
    final longitudeDelta = kaabaLongitudeRadians - longitudeRadians;

    final y = math.sin(longitudeDelta);
    final x =
        math.cos(latitudeRadians) * math.tan(kaabaLatitudeRadians) -
        math.sin(latitudeRadians) * math.cos(longitudeDelta);
    final bearing = math.atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  double needleRotation({
    required double qiblaBearing,
    required double heading,
  }) {
    return ((qiblaBearing - heading) + 360) % 360;
  }

  double angularDifference({
    required double qiblaBearing,
    required double heading,
  }) {
    final difference = needleRotation(
      qiblaBearing: qiblaBearing,
      heading: heading,
    );
    return difference > 180 ? 360 - difference : difference;
  }

  String cardinalDirection(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final normalized = ((bearing % 360) + 360) % 360;
    final index = (((normalized + 22.5) % 360) / 45).floor();
    return directions[index];
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  double _toDegrees(double radians) => radians * 180 / math.pi;
}
