import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';

class OtherCompaniesScreen extends StatefulWidget {
  const OtherCompaniesScreen({super.key});

  @override
  OtherCompanyScreen createState() => OtherCompanyScreen();
}

class OtherCompanyScreen extends State<OtherCompaniesScreen> {
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {}; // Para almacenar las rutas
  final Set<Circle> _circles = {}; // Para almacenar el círculo (radar)
  LatLng? _initialLocation;
  LatLng? _destination;
  double _currentRadius = 500; // Radio inicial del círculo (500 metros)

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Obtener la ubicación actual
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _initialLocation = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _initialLocation!,
            infoWindow: const InfoWindow(title: 'Ubicación Actual'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        _addRadar(_initialLocation!,
            _currentRadius); // Agregar el radar (círculo) con el radio inicial
      });

      _loadMarkersFromFirestore();
    } catch (e) {
      print('Error al obtener la ubicación: $e');
    }
  }

  // Cargar las empresas desde Firestore y añadir sus marcadores
  Future<void> _loadMarkersFromFirestore() async {
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('usuarios');

    final querySnapshot =
        await usersCollection.where('tipo_usuario', isEqualTo: 'empresa').get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data.containsKey('ubicacion') && data['ubicacion'] != null) {
        final LatLng markerLocation = LatLng(
            data['ubicacion']['latitude'], data['ubicacion']['longitude']);

        // Calculamos la distancia entre la ubicación actual y la ubicación del marcador
        double distanceInMeters =
            _calculateDistance(_initialLocation!, markerLocation);

        // Solo agregar el marcador si la distancia es menor o igual al radio
        if (distanceInMeters <= _currentRadius) {
          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: markerLocation,
            infoWindow: InfoWindow(
              title: data['nombre_empresa'] ?? 'Empresa',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet),
            onTap: () {
              _destination = markerLocation;
              _getRoute(_initialLocation!, _destination!); // Obtener la ruta
            },
          );
          setState(() {
            _markers.add(marker);
          });
        }
      }
    }
  }

  // Función para calcular la distancia entre dos puntos utilizando la fórmula Haversine
  double _calculateDistance(LatLng start, LatLng end) {
    const double R = 6371000; // Radio de la Tierra en metros
    double lat1 = start.latitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double deltaLat = (end.latitude - start.latitude) * pi / 180;
    double deltaLon = (end.longitude - start.longitude) * pi / 180;

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distancia en metros
  }

  // Obtener la ruta entre dos puntos usando la Google Directions API
  Future<void> _getRoute(LatLng origin, LatLng destination) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    final Uri url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final routes = data['routes'];

      if (routes.isNotEmpty) {
        final polylinePoints =
            routes[0]['legs'][0]['steps'].map<LatLng>((step) {
          final lat = step['end_location']['lat'];
          final lng = step['end_location']['lng'];
          return LatLng(lat, lng);
        }).toList();

        // Dibujar la ruta en el mapa
        setState(() {
          _polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            visible: true,
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
          ));
        });
      }
    } else {
      print('Error al obtener la ruta');
    }
  }

  // Método para agregar un círculo (radar) en el mapa
  void _addRadar(LatLng location, double radius) {
    setState(() {
      _circles.add(Circle(
        circleId: const CircleId('radar'),
        center: location,
        radius: radius, // Usar el valor de radio dinámico
        fillColor: Colors.blue.withOpacity(0.2),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ));
    });
  }

  // Configuración del mapa
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Otras Empresas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF643CB9),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          // Slider para seleccionar el radio del radar
          Expanded(
            child: _initialLocation == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialLocation!,
                      zoom: 14,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    circles: _circles, // Mostrar el círculo (radar) en el mapa
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    onTap: (LatLng location) {
                      setState(() {
                        _destination = location;
                      });
                      // Llamar al método para obtener la ruta
                      if (_initialLocation != null && _destination != null) {
                        _getRoute(_initialLocation!, _destination!);
                      }
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Radio del radar (en metros):'),
                Slider(
                  value: _currentRadius,
                  min: 100,
                  max: 5000,
                  divisions: 50,
                  label: '${_currentRadius.toStringAsFixed(0)} m',
                  onChanged: (double newValue) {
                    setState(() {
                      _currentRadius = newValue;
                      _circles.clear(); // Limpiar los círculos antiguos
                      _markers.clear();
                      if (_initialLocation != null) {
                        _markers.add(
                          Marker(
                            markerId: const MarkerId('current_location'),
                            position: _initialLocation!,
                            infoWindow:
                                const InfoWindow(title: 'Ubicación Actual'),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue),
                          ),
                        );
                        _addRadar(_initialLocation!,
                            _currentRadius); // Agregar el nuevo radar
                      }
                    });
                    _loadMarkersFromFirestore(); // Recargar los marcadores según el nuevo radio
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
