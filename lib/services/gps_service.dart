import 'package:geolocator/geolocator.dart';

class GpsService {
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  Future<Map<String, double>?> snapPosition() async {
    final position = await getCurrentPosition();
    if (position == null) return null;
    return {
      'lat': position.latitude,
      'lon': position.longitude,
      'altitude': position.altitude,
      'accuracy': position.accuracy,
    };
  }
}