import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matrix/matrix.dart';

class ProtestEvent {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String locationName; // e.g., "City Hall"
  final String? roomId; // ID of the dedicated Matrix chat room
  final String? series; // e.g., "No Kings"

  ProtestEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.locationName = '',
    this.roomId,
    this.series,
  });

  // Convert Firestore database data into a Dart object
  factory ProtestEvent.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProtestEvent(
      id: doc.id,
      title: data['title'] ?? 'Untitled Action',
      description: data['description'] ?? '',
      timestamp: data['timestamp'] is Timestamp 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 44.4759,
      longitude: (data['longitude'] as num?)?.toDouble() ?? -73.2121,
      locationName: data['locationName'] ?? '',
      roomId: data['roomId']?.toString(),
      series: data['series']?.toString(),
    );
  }

  // Helper to parse from a JSON map (used by both Matrix factories)
  static ProtestEvent fromMap(String eventId, Map<String, dynamic> content) {
    double parseCoord(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return ProtestEvent(
      id: eventId,
      title: content['title']?.toString() ?? 'Untitled Action',
      description: content['description']?.toString() ?? '',
      timestamp: content['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch((content['timestamp'] as num).toInt())
          : DateTime.now(),
      latitude: parseCoord(content['latitude'], 44.4759),
      longitude: parseCoord(content['longitude'], -73.2121),
      locationName: content['locationName']?.toString() ?? '',
      roomId: content['roomId']?.toString(),
      series: content['series']?.toString(),
    );
  }

  factory ProtestEvent.fromMatrixEvent(Event event) {
    return fromMap(event.eventId, event.content);
  }

  factory ProtestEvent.fromStrippedStateEvent(StrippedStateEvent event) {
    return fromMap("stripped_${DateTime.now().millisecondsSinceEpoch}", event.content);
  }
}
