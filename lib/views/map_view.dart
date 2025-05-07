import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
// import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';
import '../components/search.dart';
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  
  
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(21.0285, 105.8542);
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  final TextEditingController _searchController = TextEditingController();

  // Dữ liệu giả lập: danh sách các địa điểm và sản phẩm chúng cung cấp
  final List<Map<String, dynamic>> _locations = [
    {
      'name': 'Cửa hàng rau sạch Ba Đình',
      'products': ['Cà chua', 'Dâu tây'],
      'position': const LatLng(21.0285, 105.8542),
    },
    {
      'name': 'Vườn rau Hữu Cơ Tây Hồ',
      'products': ['Cà chua', 'Rau xà lách'],
      'position': const LatLng(21.0400, 105.8550),
    },
    {
      'name': 'Nông trại Đà Lạt 1',
      'products': ['Dâu tây', 'Cam'],
      'position': const LatLng(11.9404, 108.4583),
    },
    {
      'name': 'Nông trại Đà Lạt 2',
      'products': ['Cam', 'Rau cải'],
      'position': const LatLng(11.9450, 108.4600),
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _initialPosition,
            infoWindow: const InfoWindow(
              title: 'Vị trí hiện tại',
              snippet: 'Bạn đang ở đây',
            ),
          ),
        );
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _initialPosition, zoom: 14.0),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.isEmpty) {
      setState(() {
        _markers.clear();
        _polygons.clear();
      });
      return;
    }

    // Tìm các địa điểm cung cấp sản phẩm khớp với từ khóa
    final filteredLocations = _locations.where((location) {
      final products = location['products'] as List<dynamic>;
      return products.any((product) => product.toString().toLowerCase().contains(query.toLowerCase()));
    }).toList();

    if (filteredLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy địa điểm cung cấp sản phẩm')),
      );
      setState(() {
        _markers.clear();
        _polygons.clear();
      });
      return;
    }

    // Xóa marker và polygon cũ, thêm marker mới
    setState(() {
      _markers.clear();
      _polygons.clear();
      for (var location in filteredLocations) {
        _markers.add(
          Marker(
            markerId: MarkerId(location['name']),
            position: location['position'],
            infoWindow: InfoWindow(
              title: location['name'],
              snippet: 'Cung cấp: ${location['products'].join(', ')}',
            ),
            onTap: () {
              _mapController?.showMarkerInfoWindow(MarkerId(location['name']));
            },
          ),
        );
      }

      // Tạo Polygon để khoanh vùng
      if (filteredLocations.length > 1) {
        final List<LatLng> polygonPoints = filteredLocations
            .map((location) => location['position'] as LatLng)
            .toList();
        _polygons.add(
          Polygon(
            polygonId: const PolygonId('search_area'),
            points: polygonPoints,
            fillColor: Colors.blue.withOpacity(0.2),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
        );
      }
    });

    // Di chuyển camera đến vùng bao quanh các marker
    if (_mapController != null && filteredLocations.isNotEmpty) {
      final bounds = _calculateBounds(filteredLocations);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50), // Padding 50
      );
    }
  }

  // Hàm tính LatLngBounds để bao quanh các địa điểm
  LatLngBounds _calculateBounds(List<Map<String, dynamic>> locations) {
    double? minLat, maxLat, minLng, maxLng;
    for (var location in locations) {
      final pos = location['position'] as LatLng;
      minLat = minLat == null ? pos.latitude : min(minLat, pos.latitude);
      maxLat = maxLat == null ? pos.latitude : max(maxLat, pos.latitude);
      minLng = minLng == null ? pos.longitude : min(minLng, pos.longitude);
      maxLng = maxLng == null ? pos.longitude : max(maxLng, pos.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) => _mapController = controller,
          initialCameraPosition: CameraPosition(
            target: _initialPosition,
            zoom: 14.0,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        ),
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: CustomSearchBar(
            controller: _searchController,
            onSubmitted: (query) => _onSearchSubmitted(query),
          ),
        ),
      ],
    );
  }
}