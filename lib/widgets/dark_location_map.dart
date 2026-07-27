import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoom(double scaleFactor) {
    setState(() {
      final Matrix4 matrix = _transformationController.value.clone();
      matrix.scale(scaleFactor);
      _transformationController.value = matrix;
    });
  }

  void _resetMapPosition() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎯 Map Centered to Your Live Device Location (Chennai Region)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  final List<String> _categories = [
    'All',
    'Power Tools',
    'Concrete',
    'Lifting',
    'Safety',
    'Lighting'
  ];

  final List<Map<String, dynamic>> _mapPins = [
    {
      'id': 1,
      'name': 'Electric Cement Mixer',
      'location': 'Poonamallee, Chennai',
      'category': 'Concrete',
      'status': 'Available',
      'color': Colors.green,
      'x': 0.52,
      'y': 0.48,
    },
    {
      'id': 2,
      'name': 'MIG Welder Pro',
      'location': 'Avadi, Chennai',
      'category': 'Power Tools',
      'status': 'Power Tools',
      'color': Colors.amber,
      'x': 0.62,
      'y': 0.25,
    },
    {
      'id': 3,
      'name': 'Your Location (Customer Site)',
      'location': 'Kundrathur, Chennai',
      'category': 'You',
      'status': 'You',
      'color': Colors.blue,
      'x': 0.47,
      'y': 0.52,
    },
    {
      'id': 4,
      'name': 'Diesel Generator 10kVA',
      'location': 'Sriperumbudur, Chennai',
      'category': 'Power Tools',
      'status': 'Booked',
      'color': Colors.red,
      'x': 0.32,
      'y': 0.72,
    },
    {
      'id': 5,
      'name': 'CAT Hydraulic Excavator',
      'location': 'Tambaram, Chennai',
      'category': 'Lifting',
      'status': 'Booked',
      'color': Colors.red,
      'x': 0.65,
      'y': 0.82,
    },
    {
      'id': 6,
      'name': 'Multi-Purpose Folding Ladder',
      'location': 'Vandalur, Chennai',
      'category': 'Safety',
      'status': 'Available',
      'color': Colors.green,
      'x': 0.58,
      'y': 0.90,
    },
    {
      'id': 7,
      'name': 'LED Tower Lighting Unit',
      'location': 'Tiruvallur, Chennai',
      'category': 'Lighting',
      'status': 'Available',
      'color': Colors.green,
      'x': 0.25,
      'y': 0.18,
    },
  ];

  List<Map<String, dynamic>> get _filteredPins {
    if (_selectedCategory == 'All') return _mapPins;
    return _mapPins.where((p) => p['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    const double mapCanvasWidth = 900.0;
    final double mapCanvasHeight = widget.height * 1.5;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Moveable Interactive Map Viewer (Pan, Drag, Zoom according to location)
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
                    // Real OpenStreetMap CartoDB Dark Tile Layer Grid
                    _buildRealMapTileGrid(mapCanvasWidth, mapCanvasHeight),


                    // Moveable Map Equipment Pins
                    ..._filteredPins.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final pin = entry.value;
                      final bool isSelected = _selectedPinIndex == idx;

                      return Positioned(
                        left: mapCanvasWidth * (pin['x'] as double) - 16,
                        top: mapCanvasHeight * (pin['y'] as double) - 16,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedPinIndex = idx);
                            if (widget.onPinSelected != null) {
                              widget.onPinSelected!(pin);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📍 ${pin['name']} (${pin['location']}) - Status: ${pin['status']}'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: pin['color'] as Color,
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (pin['color'] as Color).withOpacity(0.9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.black,
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (pin['color'] as Color).withOpacity(0.6),
                                  blurRadius: isSelected ? 12 : 6,
                                  spreadRadius: isSelected ? 3 : 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              pin['category'] == 'You' ? Icons.my_location : Icons.location_on,
                              color: Colors.white,
                              size: isSelected ? 22 : 16,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Top Category Filter Bar
            if (widget.showCategoryFilter)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: SingleChildScrollView(
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
                              color: active ? Colors.black : Colors.white70,
                              fontWeight: active ? FontWeight.bold : FontWeight.normal,
                              fontSize: 11,
                            ),
                          ),
                          selected: active,
                          selectedColor: AppTheme.primaryYellow,
                          backgroundColor: const Color(0xFF1E222A),
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Map Movement & Zoom Controls (+ / - / Location Recenter)
            Positioned(
              top: widget.showCategoryFilter ? 64 : 12,
              right: 12,
              child: Column(
                children: [
                  _buildZoomBtn(Icons.add, () => _zoom(1.25)),
                  const SizedBox(height: 4),
                  _buildZoomBtn(Icons.remove, () => _zoom(0.8)),
                  const SizedBox(height: 4),
                  _buildZoomBtn(Icons.my_location, _resetMapPosition),
                ],
              ),
            ),


            // Map Legend Box on Bottom Left
            if (widget.showLegend)
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141820).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _LegendItem(color: Colors.green, label: 'Available'),
                      SizedBox(height: 3),
                      _LegendItem(color: Colors.amber, label: 'Power Tools'),
                      SizedBox(height: 3),
                      _LegendItem(color: Colors.blue, label: 'You'),
                      SizedBox(height: 3),
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

  Widget _buildZoomBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E222A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildRealMapTileGrid(double canvasWidth, double canvasHeight) {
    const int startTileX = 2959;
    const int startTileY = 1886;
    const int numCols = 4;
    const int numRows = 3;

    return SizedBox(
      width: canvasWidth,
      height: canvasHeight,
      child: Stack(
        children: [
          // Fallback vector painter map
          CustomPaint(
            size: Size(canvasWidth, canvasHeight),
            painter: _DarkMapPainter(zoom: _zoomLevel),
          ),

          // Real OpenStreetMap CartoDB Dark Matter Tile Grid Layer
          for (int r = 0; r < numRows; r++)
            for (int c = 0; c < numCols; c++)
              Positioned(
                left: c * (canvasWidth / numCols),
                top: r * (canvasHeight / numRows),
                width: canvasWidth / numCols,
                height: canvasHeight / numRows,
                child: Image.network(
                  'https://a.basemaps.cartocdn.com/dark_all/12/${startTileX + c}/${startTileY + r}.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      'https://tile.openstreetmap.org/12/${startTileX + c}/${startTileY + r}.png',
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.7),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (ctx, err, st) => const SizedBox(),
                    );
                  },
                ),
              ),

          // Tech overlay tint
          Container(
            width: canvasWidth,
            height: canvasHeight,
            color: Colors.black.withOpacity(0.15),
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
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// Custom Painter to render dark theme vector map grid & roads
class _DarkMapPainter extends CustomPainter {
  final double zoom;
  _DarkMapPainter({required this.zoom});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0F1115);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = const Color(0xFF222834)
      ..strokeWidth = 2.5 * zoom
      ..style = PaintingStyle.stroke;

    final mainRoadPaint = Paint()
      ..color = const Color(0xFF323B4D)
      ..strokeWidth = 4.5 * zoom
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.25),
      fontSize: 11 * zoom,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    );

    // Draw Main Highways
    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.cubicTo(size.width * 0.3, size.height * 0.25, size.width * 0.6, size.height * 0.45, size.width, size.height * 0.35);
    canvas.drawPath(path1, mainRoadPaint);

    final path2 = Path();
    path2.moveTo(size.width * 0.4, 0);
    path2.quadraticBezierTo(size.width * 0.5, size.height * 0.5, size.width * 0.7, size.height);
    canvas.drawPath(path2, mainRoadPaint);

    // Minor Connecting Roads
    final path3 = Path();
    path3.moveTo(size.width * 0.1, size.height * 0.7);
    path3.lineTo(size.width * 0.9, size.height * 0.6);
    canvas.drawPath(path3, roadPaint);

    // Draw Region Labels (Matching Screenshot Region Names)
    _drawText(canvas, 'Tiruvallur', Offset(size.width * 0.18, size.height * 0.15), textStyle);
    _drawText(canvas, 'AVADI', Offset(size.width * 0.62, size.height * 0.22), textStyle);
    _drawText(canvas, 'Poonamallee', Offset(size.width * 0.58, size.height * 0.42), textStyle);
    _drawText(canvas, 'Kundrathur', Offset(size.width * 0.56, size.height * 0.60), textStyle);
    _drawText(canvas, 'Sriperumbudur', Offset(size.width * 0.22, size.height * 0.72), textStyle);
    _drawText(canvas, 'TAMBARAM', Offset(size.width * 0.60, size.height * 0.82), textStyle);
    _drawText(canvas, 'Vandalur', Offset(size.width * 0.55, size.height * 0.92), textStyle);
    _drawText(canvas, 'CHENNAI', Offset(size.width * 0.82, size.height * 0.32), textStyle);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _DarkMapPainter oldDelegate) => oldDelegate.zoom != zoom;
}
