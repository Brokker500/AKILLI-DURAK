import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(39.6518, 27.8906);
  Set<Marker> _markers = {};
  List<dynamic> _stops = [];
  bool isWaiting = false;
  String? currentStopName;

  @override
  void initState() {
    super.initState();
    _loadBusStops();
    _checkLocationPermission();
  }

  Future<void> _loadBusStops() async {
    final String jsonString = await rootBundle.loadString('assets/stops.json');
    final List<dynamic> data = json.decode(jsonString);

    _stops = data;

    Set<Marker> markers = {};

    for (var stop in data) {
      markers.add(
        Marker(
          markerId: MarkerId(stop['stopId']),
          position: LatLng(stop['lat'], stop['lng']),
          infoWindow: InfoWindow(
            title: stop['name'],
            snippet: '${stop['waitingCount']} kişi bekliyor',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  void _toggleWaiting() async {
    if (!isWaiting) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double userLat = position.latitude;
      double userLng = position.longitude;

      var nearest = _stops.reduce((a, b) {
        double distA = _distance(userLat, userLng, a['lat'], a['lng']);
        double distB = _distance(userLat, userLng, b['lat'], b['lng']);
        return distA < distB ? a : b;
      });

      setState(() {
        isWaiting = true;
        currentStopName = nearest['name'];
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Bekleme Bildirimi"),
          content: Text("${nearest['name']} durağına bildirim gönderildi."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Tamam"))],
        ),
      );

      print("Bekleme bildirimi gönderilen durak: ${nearest['name']}");
    } else {
      setState(() {
        isWaiting = false;
        print("Bekleme bildirimi iptal edildi: $currentStopName");
        currentStopName = null;
      });
    }
  }

  double _distance(lat1, lng1, lat2, lng2) {
    return sqrt(pow(lat1 - lat2, 2) + pow(lng1 - lng2, 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Durak Haritası')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: CameraPosition(target: _center, zoom: 14.0),
            markers: _markers,
            myLocationEnabled: true,
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _toggleWaiting,
              child: Text(isWaiting ? "Beklemekten Vazgeç" : "Durakta Bekliyorum"),
            ),
          )
        ],
      ),
    );
  }
}

class DriverMapScreen extends MapScreen {}
