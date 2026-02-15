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
  final LatLng _burlington = const LatLng(44.4759, -73.2121);
  final Stream<QuerySnapshot> _eventsStream = 
      FirebaseFirestore.instance.collection('events').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resistance Map'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return const Center(child: Text('Error loading data. Check console.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final markers = snapshot.data!.docs.map((doc) {
            final event = ProtestEvent.fromSnapshot(doc);
            return Marker(
              point: LatLng(event.latitude, event.longitude),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showEventInfo(event),
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            );
          }).toList();

          return FlutterMap(
            options: MapOptions(
              initialCenter: _burlington,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
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
        backgroundColor: const Color(0xFFB71C1C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showEventInfo(ProtestEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(event.title),
        content: Text(event.description),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  Future<void> _addTestEvent() async {
    await FirebaseFirestore.instance.collection('events').add({
      'title': 'Rally #${DateTime.now().second}',
      'description': 'Test Event',
      'timestamp': Timestamp.now(),
      'latitude': 44.4759 + (0.001 * (DateTime.now().second % 10)), 
      'longitude': -73.2121 + (0.001 * (DateTime.now().second % 5)),
    });
  }
}