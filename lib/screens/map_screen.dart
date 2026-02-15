import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// NOTE: We removed Cloud Firestore imports for this test

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LatLng _burlington = const LatLng(44.4759, -73.2121);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resistance Map (OFFLINE TEST)'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _burlington,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            // Using standard OSM tiles
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'chat.resistance',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _burlington,
                width: 80,
                height: 80,
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database is disabled for this test')),
          );
        },
        backgroundColor: const Color(0xFFB71C1C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}