import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Default center (Burlington, VT)
  final LatLng _initialCenter = const LatLng(44.4759, -73.2121);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resistance Map'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Convert database documents into Map Markers
          final markers = snapshot.data!.docs.map((doc) {
            final event = ProtestEvent.fromSnapshot(doc);
            return Marker(
              point: LatLng(event.latitude, event.longitude),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showEventDetails(event),
                child: const Icon(
                  Icons.location_on, 
                  color: Colors.red, 
                  size: 40
                ),
              ),
            );
          }).toList();

          return FlutterMap(
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                // OpenStreetMap Tile Server
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'chat.resistance',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTestEvent,
        backgroundColor: Colors.red[900],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showEventDetails(ProtestEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.description),
            const SizedBox(height: 10),
            Text('Time: ${event.timestamp.toString().split('.')[0]}', 
                 style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper to add a dummy event to test the database connection
  Future<void> _addTestEvent() async {
    await FirebaseFirestore.instance.collection('events').add({
      'title': 'Rally #${DateTime.now().second}',
      'description': 'Spontaneous gathering in Burlington',
      'timestamp': Timestamp.now(),
      // Add slightly random offset so markers don't stack perfectly
      'latitude': 44.4759 + (0.001 * (DateTime.now().second % 5)),
      'longitude': -73.2121 + (0.001 * (DateTime.now().second % 5)),
    });
  }
}