import 'package:flutter_test/flutter_test.dart';
import 'package:quran/models/prayer_time_model.dart';
import 'package:quran/services/qibla_service.dart';

void main() {
  final service = QiblaService();

  test('computes expected qibla bearing for Erbil', () {
    final bearing = service.qiblaBearing(
      const DeviceLocation(
        latitude: 36.1911,
        longitude: 44.0092,
        city: 'Erbil',
      ),
    );

    expect(bearing, greaterThan(194));
    expect(bearing, lessThan(196));
    expect(service.cardinalDirection(bearing), 'S');
  });

  test('needle rotation and angular difference normalize correctly', () {
    final rotation = service.needleRotation(qiblaBearing: 195, heading: 20);
    final difference = service.angularDifference(
      qiblaBearing: 195,
      heading: 20,
    );

    expect(rotation, 175);
    expect(difference, 175);
  });
}
