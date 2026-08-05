import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../themes/app_theme.dart';

class DarkLocationMap extends StatefulWidget {
  final String title;
  final double height;
  final bool showCategoryFilter;
  final bool showLegend;
  final Function(Map<String, dynamic> pin)? onPinSelected;

  const DarkLocationMap({
    super.key,
    this.title = 'Live Equipment & Location Map',
    this.height = 320,
    this.showCategoryFilter = true,
    this.showLegend = true,
    this.onPinSelected,
  });

  @override
  State<DarkLocationMap> createState() => _DarkLocationMapState();
}

class _DarkLocationMapState extends State<DarkLocationMap> {
  String _selectedCategory = 'All';
  double _zoomLevel = 1.0;
  int? _selectedPinIndex;
  final TransformationController _transformationController = TransformationController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLocating = true;
  double _deviceLat = 13.0574; // Default location
  double _deviceLon = 80.0451; // Default location
  String _deviceCity = 'Detecting...';

  List<Map<String, dynamic>> _dynamicPins = [];

  final List<String> _categories = [
    'All',
    'Power Tools',
    'Concrete',
    'Lifting',
    'Safety',
    'Lighting'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRealDeviceLocation();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRealDeviceLocation() async {
    if (mounted) {
      setState(() => _isLocating = true);
    }

    // 1. Primary: Hardware Device / Browser GPS Permission & Location Request
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );

        final double lat = position.latitude;
        final double lon = position.longitude;

        String city = 'Your Area';
        try {
          final revRes = await http
              .get(Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json'))
              .timeout(const Duration(seconds: 3));
          if (revRes.statusCode == 200) {
            final revData = jsonDecode(revRes.body);
            final addr = revData['address'] ?? {};
            city = addr['city'] ?? addr['town'] ?? addr['suburb'] ?? addr['county'] ?? addr['state'] ?? 'Your Location';
          }
        } catch (_) {}

        _updateLocationState(lat, lon, '$city Live Device GPS', city);
        return;
      }
    } catch (e) {
      debugPrint('Geolocator hardware fetch note: $e');
    }

    // 2. Secondary Fallback: Network IP Geolocation
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double lat = (data['latitude'] as num?)?.toDouble() ?? 13.0574;
        final double lon = (data['longitude'] as num?)?.toDouble() ?? 80.0451;
        final String city = data['city'] as String? ?? 'Chennai';
        final String region = data['region'] as String? ?? 'Tamil Nadu';

        _updateLocationState(lat, lon, '$city, $region', city);
        return;
      }
    } catch (_) {}

    // 3. Default Fallback
    _updateLocationState(13.0574, 80.0451, 'Chennai, Tamil Nadu', 'Chennai');
  }

  void _updateLocationState(double lat, double lon, String address, String city) {
    if (!mounted) return;

    final List<Map<String, dynamic>> pins = [
      {
        'id': 1,
        'name': '📍 Your Live Device Location',
        'location': '$address (${lat.toStringAsFixed(4)}°, ${lon.toStringAsFixed(4)}°)',
        'category': 'You',
        'status': 'Live GPS Device',
        'color': Colors.blue,
        'x': 0.50,
        'y': 0.50,
        'lat': lat,
        'lon': lon,
      },
      {
        'id': 2,
        'name': 'Electric Cement Mixer Pro',
        'location': 'Poonamallee, Chennai',
        'category': 'Concrete',
        'status': 'Available',
        'color': Colors.green,
        'x': 0.56,
        'y': 0.44,
        'lat': lat + 0.008,
        'lon': lon + 0.012,
      },
      {
        'id': 3,
        'name': 'MIG Heavy Welder 400A',
        'location': 'Avadi, Chennai',
        'category': 'Power Tools',
        'status': 'Power Tools',
        'color': Colors.amber,
        'x': 0.62,
        'y': 0.35,
        'lat': lat + 0.015,
        'lon': lon + 0.018,
      },
      {
        'id': 4,
        'name': 'Diesel Silent Generator 15kVA',
        'location': 'Sriperumbudur, Chennai',
        'category': 'Power Tools',
        'status': 'Booked',
        'color': Colors.red,
        'x': 0.38,
        'y': 0.65,
        'lat': lat - 0.012,
        'lon': lon - 0.015,
      },
      {
        'id': 5,
        'name': 'CAT Hydraulic Heavy Excavator',
        'location': 'Tambaram, Chennai',
        'category': 'Lifting',
        'status': 'Booked',
        'color': Colors.red,
        'x': 0.70,
        'y': 0.75,
        'lat': lat - 0.022,
        'lon': lon + 0.025,
      },
      {
        'id': 6,
        'name': 'Multi-Purpose Folding Ladder',
        'location': 'Kundrathur, Chennai',
        'category': 'Safety',
        'status': 'Available',
        'color': Colors.green,
        'x': 0.44,
        'y': 0.58,
        'lat': lat - 0.006,
        'lon': lon - 0.008,
      },
      {
        'id': 7,
        'name': 'LED Mobile Tower Lighting',
        'location': 'Tiruvallur, Chennai',
        'category': 'Lighting',
        'status': 'Available',
        'color': Colors.green,
        'x': 0.30,
        'y': 0.28,
        'lat': lat + 0.018,
        'lon': lon - 0.022,
      },
    ];

    setState(() {
      _deviceLat = lat;
      _deviceLon = lon;
      _deviceCity = city;
      _dynamicPins = pins;
      _isLocating = false;
      _transformationController.value = Matrix4.identity();
    });
  }

  void _zoom(double scaleFactor) {
    setState(() {
      final Matrix4 matrix = _transformationController.value.clone();
      matrix.scale(scaleFactor);
      _transformationController.value = matrix;
    });
  }

  void _resetMapPosition() {
    _fetchRealDeviceLocation();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎯 Recentered to Live GPS Device Location (${_deviceLat.toStringAsFixed(4)}°, ${_deviceLon.toStringAsFixed(4)}°)'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredPins {
    if (_selectedCategory == 'All') return _dynamicPins;
    return _dynamicPins.where((p) => p['category'] == _selectedCategory).toList();
  }

  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  int _latToTileY(double lat, int zoom) {
    double latRad = lat * pi / 180.0;
    return ((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) / 2.0 * (1 << zoom)).floor();
  }

  @override
  Widget build(BuildContext context) {
    const double mapCanvasWidth = 900.0;
    final double mapCanvasHeight = widget.height * 1.5;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E3DF), // Google Maps signature background color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Interactive Real Google Maps Tiles Viewer
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.6,
              maxScale: 3.5,
              boundaryMargin: const EdgeInsets.all(400),
              panEnabled: true,
              scaleEnabled: true,
              child: SizedBox(
                width: mapCanvasWidth,
                height: mapCanvasHeight,
                child: Stack(
                  children: [
                    // Real Google Maps / OpenStreetMap Voyager Color Tile Grid
                    _buildGoogleMapTileGrid(mapCanvasWidth, mapCanvasHeight),

                    // Map Pins
                    ..._filteredPins.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final pin = entry.value;
                      final bool isSelected = _selectedPinIndex == idx;
                      final bool isUserPin = pin['category'] == 'You';

                      return Positioned(
                        left: mapCanvasWidth * (pin['x'] as double) - 18,
                        top: mapCanvasHeight * (pin['y'] as double) - 18,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedPinIndex = idx);
                            if (widget.onPinSelected != null) {
                              widget.onPinSelected!(pin);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📍 ${pin['name']} - ${pin['location']}'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: pin['color'] as Color,
                              ),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: EdgeInsets.all(isUserPin ? 7 : 5),
                                decoration: BoxDecoration(
                                  color: (pin['color'] as Color),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.amberAccent : Colors.white,
                                    width: isSelected ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: isSelected ? 12 : 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isUserPin ? Icons.my_location : Icons.location_on,
                                  color: Colors.white,
                                  size: isUserPin ? 18 : 14,
                                ),
                              ),
                              if (isUserPin) ...[
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade800,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: const Text(
                                    'YOU ARE HERE',
                                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Google Maps Floating Search Bar (Top Left)
            Positioned(
              top: 12,
              left: 12,
              right: widget.showCategoryFilter ? 12 : 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black54, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Search Google Maps',
                            style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w400),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showCategoryFilter) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final bool active = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                cat,
                                style: TextStyle(
                                  color: active ? Colors.white : Colors.black87,
                                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
                                ),
                              ),
                              selected: active,
                              selectedColor: AppTheme.primaryYellow,
                              backgroundColor: Colors.white,
                              elevation: 2,
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Google Maps White Floating Action Controls (Bottom Right)
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                children: [
                  _buildGoogleMapControlBtn(Icons.add, () => _zoom(1.25)),
                  const SizedBox(height: 6),
                  _buildGoogleMapControlBtn(Icons.remove, () => _zoom(0.8)),
                  const SizedBox(height: 6),
                  _buildGoogleMapControlBtn(Icons.my_location, _resetMapPosition, isBlue: true),
                ],
              ),
            ),

            // Google Maps Legend Box (Bottom Left)
            if (widget.showLegend)
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: Row(
                    children: const [
                      _LegendItem(color: Colors.green, label: 'Available'),
                      SizedBox(width: 8),
                      _LegendItem(color: Colors.amber, label: 'Power Tools'),
                      SizedBox(width: 8),
                      _LegendItem(color: Colors.blue, label: 'You (GPS)'),
                      SizedBox(width: 8),
                      _LegendItem(color: Colors.red, label: 'Booked'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMapControlBtn(IconData icon, VoidCallback onTap, {bool isBlue = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isBlue ? Colors.blueAccent : Colors.black87,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildGoogleMapTileGrid(double canvasWidth, double canvasHeight) {
    const int zoom = 11;
    final int centerTileX = _lonToTileX(_deviceLon, zoom);
    final int centerTileY = _latToTileY(_deviceLat, zoom);

    const int numCols = 4;
    const int numRows = 3;
    final int startTileX = centerTileX - 1;
    final int startTileY = centerTileY - 1;

    return SizedBox(
      width: canvasWidth,
      height: canvasHeight,
      child: Stack(
        children: [
          // Google Maps styled fallback vector painter (light green land + blue coast)
          CustomPaint(
            size: Size(canvasWidth, canvasHeight),
            painter: _GoogleMapStylePainter(),
          ),

          // Real Google Maps / OpenStreetMap Voyager / Esri StreetMap Tile Grid
          for (int r = 0; r < numRows; r++)
            for (int c = 0; c < numCols; c++)
              Positioned(
                left: c * (canvasWidth / numCols),
                top: r * (canvasHeight / numRows),
                width: canvasWidth / numCols,
                height: canvasHeight / numRows,
                child: Image.network(
                  'https://a.basemaps.cartocdn.com/rastertiles/voyager/$zoom/${startTileX + c}/${startTileY + r}.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      'https://tile.openstreetmap.org/$zoom/${startTileX + c}/${startTileY + r}.png',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) {
                        return Image.network(
                          'https://services.arcgisonline.com/arcgis/rest/services/World_StreetMap/MapServer/tile/$zoom/${startTileY + r}/${startTileX + c}',
                          fit: BoxFit.cover,
                          errorBuilder: (c2, e2, s2) => const SizedBox(),
                        );
                      },
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Google Maps styled fallback painter with coastal water & land
class _GoogleMapStylePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Google Maps Land Color
    final landPaint = Paint()..color = const Color(0xFFF2EFE9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), landPaint);

    // Google Maps Water / Ocean Color (Right side of Chennai coast)
    final waterPaint = Paint()..color = const Color(0xFFA5BFDD);
    final oceanPath = Path();
    oceanPath.moveTo(size.width * 0.75, 0);
    oceanPath.quadraticBezierTo(size.width * 0.70, size.height * 0.5, size.width * 0.78, size.height);
    oceanPath.lineTo(size.width, size.height);
    oceanPath.lineTo(size.width, 0);
    oceanPath.close();
    canvas.drawPath(oceanPath, waterPaint);

    // Highways / Major Roads (Google Maps Yellow/Orange)
    final highwayPaint = Paint()
      ..color = const Color(0xFFFBD188)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final roadPath = Path();
    roadPath.moveTo(0, size.height * 0.4);
    roadPath.quadraticBezierTo(size.width * 0.4, size.height * 0.35, size.width * 0.75, size.height * 0.45);
    canvas.drawPath(roadPath, highwayPaint);

    final roadPath2 = Path();
    roadPath2.moveTo(size.width * 0.3, 0);
    roadPath2.quadraticBezierTo(size.width * 0.4, size.height * 0.5, size.width * 0.65, size.height);
    canvas.drawPath(roadPath2, highwayPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
