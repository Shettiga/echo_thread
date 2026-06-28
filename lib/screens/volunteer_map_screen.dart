import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:echo_thread/services/theme_service.dart';

class VolunteerMapScreen extends StatefulWidget {
  final String donationId;
  final String donorName;
  final String donorAddress;

  const VolunteerMapScreen({
    super.key,
    required this.donationId,
    required this.donorName,
    required this.donorAddress,
  });

  @override
  State<VolunteerMapScreen> createState() => _VolunteerMapScreenState();
}

class _VolunteerMapScreenState extends State<VolunteerMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  LatLng? _donorLatLng;
  double _distanceInKm = 0.0;
  int _estimatedTimeInMinutes = 0;

  bool _isLoading = true;
  String _loadingMessage = "Initializing tracking...";

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _checkPermissionAndGetLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissionAndGetLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loadingMessage = "Please enable your location services.";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _loadingMessage = "Location permissions are denied.";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _loadingMessage = "Location permissions are permanently denied.";
        });
        return;
      }

      // Permissions are granted, fetch position
      setState(() => _loadingMessage = "Fetching volunteer current location...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Load Donor Coordinates (Fallback to mock coords if not in DB)
      await _loadDonorLocation(position);

      // Start listening to live location updates
      _startLiveTracking();
    } catch (e) {
      debugPrint('[MAP_SCREEN] Setup error: $e');
      setState(() {
        _loadingMessage = "Error: $e";
      });
    }
  }

  Future<void> _loadDonorLocation(Position volunteerPos) async {
    setState(() => _loadingMessage = "Locating donor...");
    try {
      final doc = await FirebaseFirestore.instance
          .collection('donations')
          .doc(widget.donationId)
          .get();

      if (doc.exists && doc.data()?['donorLatitude'] != null) {
        final data = doc.data()!;
        _donorLatLng = LatLng(data['donorLatitude'], data['donorLongitude']);
      } else {
        // Fallback: Generate a clean, stable offset near volunteer for demonstration
        _donorLatLng = LatLng(volunteerPos.latitude + 0.008, volunteerPos.longitude + 0.012);
        // Save these coordinates back to Firestore to persist this path
        await FirebaseFirestore.instance
            .collection('donations')
            .doc(widget.donationId)
            .update({
          'donorLatitude': _donorLatLng!.latitude,
          'donorLongitude': _donorLatLng!.longitude,
        });
      }

      _calculateDistanceAndRoute();
      _updateMarkers();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[MAP_SCREEN] Failed to load donor location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startLiveTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update location every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        _calculateDistanceAndRoute();
        _updateMarkers();
        _animateCameraToPosition(position);
      }
    });
  }

  void _calculateDistanceAndRoute() {
    if (_currentPosition == null || _donorLatLng == null) return;

    // Calculate Geodesic Distance in meters
    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _donorLatLng!.latitude,
      _donorLatLng!.longitude,
    );

    setState(() {
      _distanceInKm = distanceInMeters / 1000;
      // Assume average travel speed is 40 km/h: time = (distance / 40) * 60 minutes
      _estimatedTimeInMinutes = ((_distanceInKm / 40) * 60).round();
      if (_estimatedTimeInMinutes < 1) {
        _estimatedTimeInMinutes = 1;
      }
    });

    // Draw routing Polyline
    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route_path'),
        points: [
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          _donorLatLng!,
        ],
        color: const Color(0xFF1565C0),
        width: 6,
        geodesic: true,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
  }

  void _updateMarkers() {
    if (_currentPosition == null || _donorLatLng == null) return;

    setState(() {
      _markers.clear();

      // Volunteer Marker
      _markers.add(
        Marker(
          markerId: const MarkerId('volunteer_loc'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'You (Volunteer)'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      // Donor Marker
      _markers.add(
        Marker(
          markerId: const MarkerId('donor_loc'),
          position: _donorLatLng!,
          infoWindow: InfoWindow(title: widget.donorName, snippet: widget.donorAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  Future<void> _animateCameraToPosition(Position pos) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pos.latitude, pos.longitude),
          zoom: 14.5,
        ),
      ),
    );
  }

  Future<void> _launchNavigation() async {
    if (_currentPosition == null || _donorLatLng == null) return;

    final url = 'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${_donorLatLng!.latitude},${_donorLatLng!.longitude}&travelmode=driving';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open external Google Maps: $e')),
        );
      }
    }
  }

  Future<void> _markAsDelivered() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? 'unknown';

    try {
      debugPrint("[FIRESTORE_WRITE_START] UID: $uid, Collection: donations, DocID: ${widget.donationId}");
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(widget.donationId)
          .update({
        'status': 'Delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      debugPrint("[FIRESTORE_WRITE_SUCCESS] UID: $uid, Collection: donations, DocID: ${widget.donationId}, Response: Donation delivered successfully");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Donation marked as Delivered successfully! 🎉"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Return to Dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1565C0)),
              const SizedBox(height: 20),
              Text(
                _loadingMessage,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Garment Pickup Route"),
      ),
      body: Stack(
        children: [
          // 🗺️ Google Maps Widget
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
              // Center view to fit both markers
              _fitBounds(controller);
            },
          ),

          // ℹ️ Route Detail Overlay Card
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              color: cardBg,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Garments Pickup Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "In Transit",
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Donor: ${widget.donorName}",
                      style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "Address: ${widget.donorAddress}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol(Icons.directions_car_outlined, "${_distanceInKm.toStringAsFixed(1)} km", "Distance"),
                        _buildMetricCol(Icons.access_time_outlined, "$_estimatedTimeInMinutes mins", "Travel Time"),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _launchNavigation,
                            icon: const Icon(Icons.navigation_outlined, size: 18),
                            label: const Text("Navigate App", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade800,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _markAsDelivered,
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text("Delivered", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1565C0), size: 24),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Future<void> _fitBounds(GoogleMapController controller) async {
    if (_currentPosition == null || _donorLatLng == null) return;

    double volunteerLat = _currentPosition!.latitude;
    double volunteerLng = _currentPosition!.longitude;
    double donorLat = _donorLatLng!.latitude;
    double donorLng = _donorLatLng!.longitude;

    LatLngBounds bounds;
    if (volunteerLat < donorLat) {
      bounds = LatLngBounds(
        southwest: LatLng(volunteerLat, volunteerLng < donorLng ? volunteerLng : donorLng),
        northeast: LatLng(donorLat, volunteerLng > donorLng ? volunteerLng : donorLng),
      );
    } else {
      bounds = LatLngBounds(
        southwest: LatLng(donorLat, volunteerLng < donorLng ? volunteerLng : donorLng),
        northeast: LatLng(volunteerLat, volunteerLng > donorLng ? volunteerLng : donorLng),
      );
    }

    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }
}
