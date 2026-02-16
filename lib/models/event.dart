import 'package:cloud_firestore/cloud_firestore.dart';

class ProtestEvent {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String locationName; // e.g., "City Hall"

  ProtestEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.locationName = '',
  });

  // Convert database data into a Dart object
  factory ProtestEvent.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProtestEvent(
      id: doc.id,
      title: data['title'] ?? 'Untitled Action',
      description: data['description'] ?? '',
      // Handle both Timestamp (Firestore) and String (JSON) dates safely
      timestamp: data['timestamp'] is Timestamp 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 44.4759,
      longitude: (data['longitude'] as num?)?.toDouble() ?? -73.2121,
      locationName: data['locationName'] ?? '',
    );
  }
}