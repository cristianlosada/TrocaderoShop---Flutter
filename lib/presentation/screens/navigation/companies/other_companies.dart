import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class OtherCompaniesScreen extends StatefulWidget {
  const OtherCompaniesScreen({super.key});

  @override
  OtherCompanyScreen createState() => OtherCompanyScreen();
}

class OtherCompanyScreen extends State<OtherCompaniesScreen> {
  // final TextEditingController _searchController = TextEditingController();
  // String? _selectedCategory;
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  LatLng? _initialLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Obtener ubicación actual antes de cargar los marcadores
  }

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

        // Agregar marcador de ubicación actual
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _initialLocation!,
            infoWindow: const InfoWindow(title: 'Ubicación Actual'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      // Cargar otros marcadores de Firestore una vez obtenida la ubicación actual
      _loadMarkersFromFirestore();
    } catch (e) {
      print('Error al obtener la ubicación: $e');
    }
  }

  // Cargar productos y agregar marcadores, incluyendo la ubicación del teléfono
  Future<void> _loadMarkersFromFirestore() async {
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('usuarios');

    // Cargar ubicaciones de Firestore
    final querySnapshot =
        await usersCollection.where('tipo_usuario', isEqualTo: 'empresa').get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      print(data);
      if (data.containsKey('ubicacion') && data['ubicacion'] != null) {
        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(
              data['ubicacion']['latitude'], data['ubicacion']['longitude']),
          infoWindow: InfoWindow(
            title: data['nombre_empresa'] ?? 'Empresa',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        );
        _markers.add(marker);
      }
    }

    setState(() {
      // Actualizar el conjunto de marcadores en el mapa
    });
  }

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
          color: Colors.white, // Color blanco para el ícono de retroceso
        ),
      ),
      body: Column(
        children: [
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: TextField(
          //     controller: _searchController,
          //     decoration: InputDecoration(
          //       labelText: 'Buscar por categoría',
          //       prefixIcon: const Icon(Icons.search),
          //       border: const OutlineInputBorder(),
          //       fillColor: Colors.white,
          //       filled: true,
          //       focusedBorder: OutlineInputBorder(
          //         borderSide: BorderSide(color: primaryColor, width: 2.0),
          //       ),
          //     ),
          //     onChanged: (value) {
          //       setState(() {
          //         _selectedCategory = value;
          //       });
          //     },
          //   ),
          // ),
          // const SizedBox(height: 10),
          Expanded(
            child: _initialLocation == null
                ? const Center(
                    child:
                        CircularProgressIndicator()) // Mostrar cargando si aún no hay ubicación
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialLocation!,
                      zoom: 14, // Ajusta el zoom según tus preferencias
                    ),
                    markers: _markers,
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
