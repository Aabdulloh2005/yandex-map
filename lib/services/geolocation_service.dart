import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class GeolocationService {
  static Future<void> init() async {
    LocationPermission permissionstatus = await Geolocator.checkPermission();

    if (permissionstatus == LocationPermission.denied ||
        permissionstatus == LocationPermission.deniedForever) {
      Geolocator.requestPermission();
    }
  }

  static Future<Point> getCurrentLocation() async {
    final current = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return Point(latitude: current.latitude, longitude: current.longitude);
  }
}
