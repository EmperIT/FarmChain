import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'location_detail_page.dart'; // Import your LocationDetailPage

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late WebViewController _webViewController;
  Map<String, double>? _currentPosition;
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _geojsonData;

  // Dữ liệu địa điểm (marker) with additional fields for details
  final List<Map<String, dynamic>> _locations = [
    {
      'name': 'Cửa hàng rau sạch Ba Đình',
      'products': ['Cà chua', 'Dâu tây'],
      'position': {'lat': 21.0285, 'lng': 105.8542},
      'description': 'Cửa hàng cung cấp rau sạch chất lượng cao tại Ba Đình.',
      'image': 'assets/images/ba_dinh_store.jpg', // Local image path
      'rating': 4.5,
    },
    {
      'name': 'Vườn rau Hữu Cơ Tây Hồ',
      'products': ['Cà chua', 'Rau xà lách'],
      'position': {'lat': 21.0400, 'lng': 105.8550},
      'description': 'Vườn rau hữu cơ với sản phẩm tươi ngon tại Tây Hồ.',
      'image': 'assets/images/tay_ho_farm.jpg',
      'rating': 4.8,
    },
    {
      'name': 'Nông trại Đà Lạt 1',
      'products': ['Dâu tây', 'Cam'],
      'position': {'lat': 11.9404, 'lng': 108.4583},
      'description': 'Nông trại cung cấp dâu tây và cam tươi từ Đà Lạt.',
      'image': 'assets/images/dalat_farm1.jpg',
      'rating': 4.2,
    },
    {
      'name': 'Nông trại Đà Lạt 2',
      'products': ['Cam', 'Rau cải'],
      'position': {'lat': 11.9450, 'lng': 108.4600},
      'description': 'Nông trại chuyên cung cấp cam và rau cải tại Đà Lạt.',
      'image': 'assets/images/dalat_farm2.jpg',
      'rating': 4.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('WebView loading progress: $progress%');
          },
          onPageStarted: (String url) {
            print('WebView started loading: $url');
          },
          onPageFinished: (String url) {
            print('WebView finished loading: $url');
            if (_geojsonData != null) {
              _updateMap();
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'ViewDetailChannel',
        onMessageReceived: (JavaScriptMessage message) {
          // Handle the location name received from JavaScript
          final locationName = message.message;
          final location = _locations.firstWhere(
            (loc) => loc['name'] == locationName,
            orElse: () => {},
          );
          if (location.isNotEmpty) {
            // Navigate to LocationDetailPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocationDetailPage(location: location),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không tìm thấy thông tin địa điểm')),
            );
          }
        },
      )
      ..loadFlutterAsset('assets/map.html');
    _loadGeojson();
    _getCurrentLocation();
  }

  Future<void> _loadGeojson() async {
    try {
      String jsonString = await DefaultAssetBundle.of(context).loadString('assets/regions.json');
      setState(() {
        _geojsonData = jsonDecode(jsonString);
        print('GeoJSON loaded: $_geojsonData');
        _updateMap();
      });
    } catch (e) {
      print('Error loading GeoJSON: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật dịch vụ định vị')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền định vị bị từ chối')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền định vị bị từ chối vĩnh viễn')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = {
          'lat': position.latitude,
          'lng': position.longitude,
        };
        if (_geojsonData != null) {
          _updateMap();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _updateMap() {
    if (_geojsonData == null) {
      print('GeoJSON not loaded yet');
      return;
    }

    final mapData = {
      'currentLocation': _currentPosition,
      'locations': _locations.map((loc) => {
            'name': loc['name'],
            'products': loc['products'],
            'lat': loc['position']['lat'],
            'lng': loc['position']['lng'],
          }).toList(),
      'geojson': _geojsonData,
      'searchQuery': _searchController.text,
    };
    _webViewController.runJavaScript(
      'updateMap(${jsonEncode(mapData)});',
    );
  }

  void _onSearchSubmitted(String query) {
    setState(() {
      _searchController.text = query;
      _updateMap();
    });
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
        WebViewWidget(controller: _webViewController),
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm (Cà chua, Dâu tây...)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _onSearchSubmitted(_searchController.text),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                ),
                onSubmitted: _onSearchSubmitted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}