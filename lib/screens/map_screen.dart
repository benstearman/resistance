import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resistance Map'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          // 1. Handle Errors/Loading safely
          if (snapshot.hasError) return const Center(child: Text("Error loading events"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // 2. Convert database docs to Markers
          final markers = snapshot.data!.docs.map((doc) {
            final event = ProtestEvent.fromSnapshot(doc);
            return Marker(
              point: LatLng(event.latitude, event.longitude),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showEventDetails(context, event),
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            );
          }).toList();

          // 3. Draw the Map
          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(44.4759, -73.2121), // Burlington
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
    );
  }

  void _showEventDetails(BuildContext context, ProtestEvent event) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(event.description),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}