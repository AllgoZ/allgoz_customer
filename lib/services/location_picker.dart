import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  bool _isLoading = true;
  String? _latLngText;
  MapType _mapType = MapType.satellite;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (widget.initialLocation != null) {
      _selectedLatLng = widget.initialLocation;
      _latLngText =
      "Latitude: ${_selectedLatLng!.latitude.toStringAsFixed(5)}, Longitude: ${_selectedLatLng!.longitude.toStringAsFixed(5)}";
      setState(() => _isLoading = false);
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      _selectedLatLng = LatLng(pos.latitude, pos.longitude);
      _latLngText =
      "Latitude: ${pos.latitude.toStringAsFixed(5)}, Longitude: ${pos.longitude.toStringAsFixed(5)}";
      setState(() => _isLoading = false);
    } catch (e) {
      _selectedLatLng = const LatLng(10.3851, 77.7555); // fallback
      _latLngText = "Lat: 10.3851, Lng: 77.7555";
      setState(() => _isLoading = false);
    }
  }

  void _updateLatLng(LatLng latLng) {
    setState(() {
      _selectedLatLng = latLng;
      _latLngText =
      "Latitude: ${latLng.latitude.toStringAsFixed(5)}, Longitude: ${latLng.longitude.toStringAsFixed(5)}";
    });
  }

  void _onConfirmLocation() {
    if (_selectedLatLng != null) {
      Navigator.pop(context, _selectedLatLng);
    }
  }

  void _centerToCurrentLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    final newLatLng = LatLng(pos.latitude, pos.longitude);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 17));
    _updateLatLng(newLatLng);
  }

  void _toggleMapType() {
    setState(() {
      _mapType =
      _mapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 390;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: const Text("Select Delivery Location"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLatLng!,
              zoom: 16,
            ),
            mapType: _mapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              _updateLatLng(position.target);
            },
          ),
          Center(
            child: Icon(Icons.location_pin,
                size: 40 * scaleFactor, color: Colors.red),
          ),
          Positioned(
            top: 20 * scaleFactor,
            right: 15,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: _centerToCurrentLocation,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location, color: Colors.blue),
                ),
                SizedBox(height: 10 * scaleFactor),
                FloatingActionButton.small(
                  onPressed: _toggleMapType,
                  backgroundColor: Colors.white,
                  child: Icon(
                    _mapType == MapType.normal
                        ? Icons.satellite_alt
                        : Icons.map,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // if (_latLngText != null)
          //   Positioned(
          //     bottom: 100 * scaleFactor,
          //     left: 20 * scaleFactor,
          //     right: 20 * scaleFactor,
          //     child: Container(
          //       padding: EdgeInsets.all(12 * scaleFactor),
          //       decoration: BoxDecoration(
          //         color: Colors.white,
          //         borderRadius:
          //         BorderRadius.circular(10 * scaleFactor),
          //         boxShadow: [
          //           BoxShadow(color: Colors.black26, blurRadius: 5)
          //         ],
          //       ),
          //       child: Text(
          //         _latLngText!,
          //         textAlign: TextAlign.center,
          //         style: TextStyle(fontSize: 14 * scaleFactor),
          //       ),
          //     ),
          //   ),
        ],
      ),
      bottomNavigationBar: _isLoading
          ? null
          : Padding(
        padding: EdgeInsets.all(12.0 * scaleFactor),
        child: ElevatedButton.icon(
          onPressed: _onConfirmLocation,
          icon: Icon(Icons.check),
          label: Text("Confirm Location",
              style: TextStyle(fontSize: 16 * scaleFactor)),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
                vertical: 14 * scaleFactor,
                horizontal: 20 * scaleFactor),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8 * scaleFactor),
            ),
          ),
        ),
      ),
    );
  }
}
