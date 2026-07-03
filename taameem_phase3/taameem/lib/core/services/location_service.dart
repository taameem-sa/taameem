import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // الموقع الافتراضي: الرياض
  static const LatLng defaultLocation = LatLng(24.7136, 46.6753);

  // ─── الحصول على موقع المستخدم ─────────────────────────────────────────────
  Future<LatLng> getCurrentLocation() async {
    try {
      final permission = await _checkPermission();
      if (!permission) return defaultLocation;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return defaultLocation;
    }
  }

  // ─── التحقق من الأذونات وطلبها ────────────────────────────────────────────
  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  // ─── بث الموقع بشكل مستمر ────────────────────────────────────────────────
  Stream<Position> streamLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // تحديث كل 50 متر
      ),
    );
  }

  // ─── حساب المسافة بين نقطتين (بالكيلومتر) ────────────────────────────────
  double distanceBetween(LatLng from, LatLng to) {
    final meters = Geolocator.distanceBetween(
      from.latitude, from.longitude,
      to.latitude, to.longitude,
    );
    return meters / 1000;
  }

  // ─── نص المسافة ───────────────────────────────────────────────────────────
  String distanceText(LatLng from, LatLng to) {
    final km = distanceBetween(from, to);
    if (km < 1) return '${(km * 1000).round()} متر';
    return '${km.toStringAsFixed(1)} كم';
  }
}
