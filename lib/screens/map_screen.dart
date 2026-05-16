import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../widgets/event_details_panel.dart';
import '../services/matrix_service.dart';
import 'event_edit_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _zipController = TextEditingController();
  LatLng? _currentPosition;
  bool _isSearchingZip = false;
  bool _hasCenteredInitially = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    // Removed _initLocation() to prevent early permission prompt
  }

  void _onMapReady() {
    setState(() => _isMapReady = true);
    if (_currentPosition != null && !_hasCenteredInitially) {
      _safeMapMove(_currentPosition!, 15.0);
      _hasCenteredInitially = true;
    }
  }

  void _safeMapMove(LatLng point, double zoom) {
    if (!_isMapReady) return;
    try {
      _mapController.move(point, zoom);
    } catch (e) {
      print("DIAGNOSTIC: Map move failed: $e");
    }
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // 1. Get initial position
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
          if (!_hasCenteredInitially && _isMapReady) {
            _safeMapMove(_currentPosition!, 15.0);
            _hasCenteredInitially = true;
          }
        });
      }
    } catch (e) {
      print("Error getting initial location: $e");
    }

    // 2. Listen for continuous updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
          // If we haven't centered yet (maybe the initial get failed), center on first stream update
          if (!_hasCenteredInitially && _isMapReady) {
            _safeMapMove(_currentPosition!, 15.0);
            _hasCenteredInitially = true;
          }
        });
      }
    });
  }

  Future<void> _searchZip() async {
    final zip = _zipController.text.trim();
    if (zip.length < 5) return;

    setState(() => _isSearchingZip = true);

    try {
      final response = await http.get(Uri.parse(
        "https://nominatim.openstreetmap.org/search?postalcode=$zip&country=US&format=json"
      ));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          if (_isMapReady) {
            _safeMapMove(LatLng(lat, lon), 13.0);
          }
          _hasCenteredInitially = true; // Stop auto-locating if user searched manually
          FocusScope.of(context).unfocus();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zip code not found.")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Search failed: $e")));
    } finally {
      setState(() => _isSearchingZip = false);
    }
  }

  Future<void> _centerOnUser() async {
    if (_currentPosition != null && _isMapReady) {
      _safeMapMove(_currentPosition!, 15.0);
    } else {
      // If we don't have a position, explicitly request and fetch it
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location services are disabled.")),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location permissions are denied.")),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permissions are permanently denied.")),
          );
        }
        return;
      }

      try {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(pos.latitude, pos.longitude);
            if (_isMapReady) {
              _safeMapMove(_currentPosition!, 15.0);
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error getting location: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resistance Map'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "locate_me",
            backgroundColor: Colors.white,
            onPressed: _centerOnUser,
            child: const Icon(Icons.my_location, color: Colors.black),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "add_event",
            backgroundColor: const Color(0xFFB71C1C),
            child: const Icon(Icons.add_location_alt, color: Colors.white),
            onPressed: () {
              final userId = MatrixService.instance.client?.userID ?? '';
              if (userId.contains('guest') || userId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please login to add actions.")),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EventEditScreen(event: null)),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<ProtestEvent>>(
            stream: MatrixService.instance.getProtestEvents(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) {
                if (MatrixService.instance.client?.isLogged() != true) {
                  MatrixService.instance.loginAsGuest();
                }
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data!;

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(44.4759, -73.2121),
                  initialZoom: 13.0,
                  onMapReady: _onMapReady,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'chat.resistance',
                  ),
                  MarkerLayer(
                    markers: [
                      ...events.map((event) => Marker(
                        point: LatLng(event.latitude, event.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => EventDetailsPanel(event: event),
                          ),
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      )),
                      if (_currentPosition != null)
                        Marker(
                          point: _currentPosition!,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 10, spreadRadius: 5),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          PositionfulSearch(
            zipController: _zipController,
            isSearching: _isSearchingZip,
            onSearch: _searchZip,
          ),
        ],
      ),
    );
  }
}

class PositionfulSearch extends StatelessWidget {
  final TextEditingController zipController;
  final bool isSearching;
  final VoidCallback onSearch;

  const PositionfulSearch({
    super.key,
    required this.zipController,
    required this.isSearching,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: zipController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Enter Zip Code for privacy",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              if (isSearching)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: onSearch,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
