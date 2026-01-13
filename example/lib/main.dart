import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/sphere_style.dart';
import 'package:flutter_earth_globe/point.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Earth Globe with Satellites',
      theme: ThemeData.dark(),
      home: const GlobeScreen(),
    );
  }
}

class Satellite {
  final String name;
  final double altitude; // Relative to Earth radius (1.0 = Earth surface)
  final double inclination; // Orbital inclination in radians
  double orbitAngle; // Current position in orbit (radians)
  final double orbitSpeed; // Radians per frame
  final Color color;
  final String type;
  
  Satellite({
    required this.name,
    required this.altitude,
    required this.inclination,
    required this.orbitAngle,
    required this.orbitSpeed,
    required this.color,
    required this.type,
  });
  
  void updatePosition(double deltaTime) {
    orbitAngle += orbitSpeed * deltaTime;
    if (orbitAngle > 2 * math.pi) {
      orbitAngle -= 2 * math.pi;
    }
  }
  
  // Get latitude and longitude for display on globe
  Map<String, double> getLatLng() {
    // Convert orbital position to lat/lng
    final lat = math.asin(math.sin(orbitAngle) * math.sin(inclination)) * 180 / math.pi;
    final lng = (math.atan2(
      math.sin(orbitAngle) * math.cos(inclination),
      math.cos(orbitAngle)
    ) * 180 / math.pi);
    
    return {'lat': lat, 'lng': lng};
  }
}

class GlobeScreen extends StatefulWidget {
  const GlobeScreen({Key? key}) : super(key: key);

  @override
  State<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends State<GlobeScreen> with SingleTickerProviderStateMixin {
  late FlutterEarthGlobeController _controller;
  late AnimationController _animationController;
  final List<Satellite> _satellites = [];
  bool _showSatellites = true;
  String? _selectedSatellite;

  @override
  void initState() {
    super.initState();
    
    _controller = FlutterEarthGlobeController(
      rotationSpeed: 0.05,
      isRotating: false,
      isBackgroundFollowingSphereRotation: true,
      background: Image.asset('assets/stars.jpg').image,
      surface: Image.asset('assets/earth_surface.jpg').image,
    );

    _initializeSatellites();
    
    // Animation for satellite movement
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..repeat();
    
    _animationController.addListener(() {
      if (mounted) {
        setState(() {
          for (var satellite in _satellites) {
            satellite.updatePosition(0.016);
          }
          _updateSatellitePoints();
        });
      }
    });
  }

  void _initializeSatellites() {
    // ISS - Low Earth Orbit
    _satellites.add(Satellite(
      name: 'ISS',
      altitude: 0.065,
      inclination: 51.6 * math.pi / 180,
      orbitAngle: 0,
      orbitSpeed: 0.5,
      color: Colors.cyanAccent,
      type: 'ISS',
    ));
    
    // GPS Satellites - Medium Earth Orbit
    for (int i = 0; i < 6; i++) {
      _satellites.add(Satellite(
        name: 'GPS-${i + 1}',
        altitude: 0.32,
        inclination: 55 * math.pi / 180,
        orbitAngle: i * 60.0 * math.pi / 180,
        orbitSpeed: 0.15,
        color: Colors.greenAccent,
        type: 'GPS',
      ));
    }
    
    // Starlink - Low Earth Orbit
    for (int i = 0; i < 12; i++) {
      _satellites.add(Satellite(
        name: 'Starlink-${i + 1}',
        altitude: 0.085,
        inclination: 53 * math.pi / 180,
        orbitAngle: i * 30.0 * math.pi / 180,
        orbitSpeed: 0.45,
        color: Colors.orangeAccent,
        type: 'Starlink',
      ));
    }
    
    // Geostationary satellites
    for (int i = 0; i < 4; i++) {
      _satellites.add(Satellite(
        name: 'GEO-${i + 1}',
        altitude: 0.55,
        inclination: 0,
        orbitAngle: i * 90.0 * math.pi / 180,
        orbitSpeed: 0.05,
        color: Colors.purpleAccent,
        type: 'GEO',
      ));
    }
    
    _updateSatellitePoints();
  }

  void _updateSatellitePoints() {
    if (!_showSatellites) {
      _controller.points.clear();
      return;
    }

    _controller.points.clear();
    
    for (var satellite in _satellites) {
      final coords = satellite.getLatLng();
      
      _controller.points.add(
        Point(
          id: satellite.name,
          latitude: coords['lat']!,
          longitude: coords['lng']!,
          label: satellite.name,
          style: PointStyle(
            color: satellite.color,
            size: 8,
            border: BorderSide(color: Colors.white, width: 1),
          ),
          isLabelVisible: false,
          onTap: () {
            setState(() {
              _selectedSatellite = '${satellite.name} (${satellite.type})';
            });
          },
          onHover: () {
            // Optional: show info on hover
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Earth Globe with Satellites'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(_showSatellites ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showSatellites = !_showSatellites;
                _updateSatellitePoints();
              });
            },
            tooltip: _showSatellites ? 'Hide Satellites' : 'Show Satellites',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterEarthGlobe(
            controller: _controller,
            radius: 150,
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Active Satellites',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLegendItem('ISS', Colors.cyanAccent, '1 satellite'),
                  _buildLegendItem('GPS', Colors.greenAccent, '6 satellites'),
                  _buildLegendItem('Starlink', Colors.orangeAccent, '12 satellites'),
                  _buildLegendItem('GEO', Colors.purpleAccent, '4 satellites'),
                  if (_selectedSatellite != null) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    Text(
                      'Selected:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedSatellite!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Controls',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _controller.isRotating = !_controller.isRotating;
                      setState(() {});
                    },
                    icon: Icon(_controller.isRotating ? Icons.pause : Icons.play_arrow),
                    label: Text(_controller.isRotating ? 'Pause' : 'Rotate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _controller.resetZoom();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
