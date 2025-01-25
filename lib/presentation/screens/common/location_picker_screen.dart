import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  LocationPickerScreenState createState() => LocationPickerScreenState();
}

class LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _initialLocation;
  LatLng? _pickedLocation;
  String? _pickedAddress;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _initialLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error al obtener la ubicación: $e');
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      Placemark place = placemarks[0];
      setState(() {
        _pickedAddress = "${place.street}, ${place.locality}, ${place.country}";
      });
    } catch (e) {
      print('Error al obtener la dirección: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_pickedLocation != null) {
                Navigator.of(context).pop({
                  'location': _pickedLocation,
                  'address': _pickedAddress,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, seleccione una ubicación.')),
                );
              }
            },
          ),
        ],
      ),
      body: _initialLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialLocation!,
                      zoom: 14,
                    ),
                    onTap: (location) async {
                      setState(() {
                        _pickedLocation = location;
                      });
                      await _getAddressFromCoordinates(location);
                    },
                    markers: _pickedLocation == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId('picked-location'),
                              position: _pickedLocation!,
                            ),
                          },
                  ),
                ),
                if (_pickedAddress != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Dirección: $_pickedAddress',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
    );
  }
}
