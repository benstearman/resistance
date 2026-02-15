import 'package:cloud_firestore/cloud_firestore.dart';

class ProtestEvent {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  ProtestEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  factory ProtestEvent.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProtestEvent(
      id: doc.id,
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}