import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'map_data.dart'; 

class ResultScreen extends StatelessWidget {
  final bool isCrossBreedingMode;
  final Map<String, dynamic> crossBreedingResult;
  final bool showGenusResults;
  final List<MapZone> activeZones;
  final String mapRegionName;

  const ResultScreen({
    super.key,
    required this.isCrossBreedingMode,
    required this.crossBreedingResult,
    required this.showGenusResults,
    required this.activeZones,
    required this.mapRegionName,
  });

  static const Color _accentGreen = Color(0xFF2ECC71);
  static const Color _accentRed = Color(0xFFE74C3C);
  static const Color _accentBlue = Color(0xFF3498DB);
  static const Color _glassDark = Color(0x0DFFFFFF);

  @override
  Widget build(BuildContext context) {
    // Determine compatibility based on boolean from JSON
    final bool isCompatible = !isCrossBreedingMode || (crossBreedingResult['Compatible'] == true);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Analysis Results",
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. SATELLITE MAP SECTION ---
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: isCompatible
                  ? SatelliteMapWidget(
                      zones: activeZones,
                      regionName: mapRegionName,
                    )
                  : Container(
                      width: double.infinity,
                      height: 150,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _glassDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _accentRed.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: _accentRed, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            "INCOMPATIBLE REGION",
                            style: GoogleFonts.spaceGrotesk(
                              color: _accentRed,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // --- 2. RESULT CARDS ---
            if (isCrossBreedingMode)
              _buildCrossBreedingResults()
            else
              _buildSingleGenusResults(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. CROSS-BREEDING RESULT WIDGET (UPDATED)
  // ==========================================
  Widget _buildCrossBreedingResults() {
    // --- 1. PARSE JSON DATA ---
    final bool isCompatible = crossBreedingResult['Compatible'] == true;
    final double score = double.tryParse(crossBreedingResult['Score']?.toString() ?? '0') ?? 0.0;
    final double futureScore = double.tryParse(crossBreedingResult['Future_Score']?.toString() ?? '0') ?? 0.0;
    
    final String resilience = crossBreedingResult['Resilience'] ?? "N/A";
    final String explanation = crossBreedingResult['Explanation'] ?? "No details available.";
    final String zone = crossBreedingResult['Zone'] ?? "Unknown";
    
    final Map<String, dynamic> traits = crossBreedingResult['Traits'] ?? {};
    final Map<String, dynamic> agronomics = crossBreedingResult['Agronomics'] ?? {};
    final List<dynamic> states = crossBreedingResult['States'] ?? [];

    final Color statusColor = isCompatible ? _accentGreen : _accentRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- BOX A: MAIN SCORES ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _glassDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${score.toStringAsFixed(1)}%",
                          style: GoogleFonts.spaceGrotesk(
                              color: statusColor,
                              fontSize: 42,
                              fontWeight: FontWeight.bold)),
                      Text(isCompatible ? "Compatible Pair" : "Incompatible Pair",
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                  Icon(
                    isCompatible ? Icons.check_circle : Icons.cancel,
                    color: statusColor,
                    size: 32,
                  )
                ],
              ),
              const SizedBox(height: 24),
              // Future Score & Resilience
              Row(
                children: [
                  Expanded(
                    child: _buildMiniScoreBox("Future Viability", "${futureScore.toStringAsFixed(1)}%", _accentBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniScoreBox("Resilience", resilience, Colors.orangeAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // --- BOX B: AGRONOMICS GRID ---
        Text("AGRONOMICS", style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildDetailBox(Icons.water_drop, "Water Usage", agronomics['Water_Usage']?.toString() ?? 'N/A'),
            _buildDetailBox(Icons.shower, "Irrigation", agronomics['Irrigation_Strategy']?.toString() ?? 'N/A'),
            _buildDetailBox(Icons.coronavirus, "Disease Risk", agronomics['Disease_Pressure']?.toString() ?? 'N/A'),
            _buildDetailBox(Icons.warning_amber, "Pathogen Alert", agronomics['Pathogen_Alert']?.toString() ?? 'None'),
          ],
        ),

        const SizedBox(height: 24),

        // --- BOX C: TRAITS & EXPLANATION ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Genetic Traits",
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompatible ? _accentGreen.withOpacity(0.1) : _accentRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text(zone.toUpperCase(),
                      style: GoogleFonts.inter(
                          color: isCompatible ? _accentGreen : _accentRed,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Traits with Progress Bars
              _buildTraitBar("Drought Tolerance", traits['Drought_Tol']),
              const SizedBox(height: 12),
              _buildTraitBar("Growth Speed", traits['Growth_Speed']),
              const SizedBox(height: 12),
              _buildTraitBar("Salinity Tolerance", traits['Salinity_Tol']),
              
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              
              Text("AI ANALYSIS", style: GoogleFonts.inter(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(explanation,
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 13, height: 1.5),
              ),

              if (states.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text("RECOMMENDED ZONES", style: GoogleFonts.inter(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: states.map((s) => Chip(
                    backgroundColor: Colors.white10,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    label: Text(s.toString(), style: GoogleFonts.inter(color: const Color.fromARGB(255, 63, 48, 48), fontSize: 11)),
                    avatar: const Icon(Icons.location_on, size: 12, color: _accentGreen),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                )
              ]
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. SINGLE GENUS RESULT WIDGET
  // ==========================================
  Widget _buildSingleGenusResults() {
    // Basic Parsing for Single Genus (Assuming similar structure or subset)
    final String inputPlant = crossBreedingResult['Plant_A'] ?? crossBreedingResult['plant'] ?? "Unknown";
    final double score = double.tryParse(crossBreedingResult['Score']?.toString() ?? '0') ?? 0.0;
    final String explanation = crossBreedingResult['Explanation'] ?? "Analysis complete.";
    final Map<String, dynamic> traits = crossBreedingResult['Traits'] ?? {};

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _glassDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("GENUS OPTIMIZATION", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 24),
              
              Center(
                child: Column(
                  children: [
                    Text(inputPlant, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text("${score.toStringAsFixed(1)}%", style: GoogleFonts.spaceGrotesk(color: _accentGreen, fontSize: 56, fontWeight: FontWeight.bold, height: 1.0)),
                    Text("Optimization Score", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // Reusing Trait Bar Logic
              if (traits.isNotEmpty) ...[
                _buildTraitBar("Drought Tolerance", traits['Drought_Tol']),
                const SizedBox(height: 12),
                _buildTraitBar("Growth Speed", traits['Growth_Speed']),
                const SizedBox(height: 12),
                _buildTraitBar("Salinity Tolerance", traits['Salinity_Tol']),
                const SizedBox(height: 24),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
              ],

              Text(explanation, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.6)),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildMiniScoreBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 9)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTraitBar(String label, dynamic value) {
    // Safely parse value to double (0-100)
    double val = double.tryParse(value.toString()) ?? 50.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
            Text("${val.toStringAsFixed(0)}%", style: GoogleFonts.inter(color: _accentGreen, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val / 100,
            backgroundColor: Colors.white10,
            color: _accentGreen,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// SATELLITE MAP WIDGETS (Unchanged)
// ==========================================
class SatelliteMapWidget extends StatelessWidget {
  final List<MapZone> zones;
  final String regionName;
  const SatelliteMapWidget({super.key, required this.zones, required this.regionName});

  @override
  Widget build(BuildContext context) {
    // Centered on Algeria
    final LatLng countryCenter = const LatLng(28.0, 2.0);
    final Color scanColor = zones.isNotEmpty ? zones.first.color : Colors.cyanAccent;

    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: scanColor.withOpacity(0.15), blurRadius: 15, spreadRadius: 1)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: countryCenter,
                initialZoom: 5.0,
                minZoom: 4.0, maxZoom: 7.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom),
              ),
              children: [
                TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', subdomains: const ['a', 'b', 'c', 'd']),
                MarkerLayer(markers: zones.map((zone) {
                    return Marker(point: zone.coordinates, width: 40, height: 40, child: PulsingRadar(color: zone.color));
                }).toList()),
              ],
            ),
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: GridOverlayPainter()))),
            Positioned.fill(child: IgnorePointer(child: ScannerAnimation(color: scanColor))),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SATELLITE FEED: ALGERIA_WIDE_BAND", style: GoogleFonts.courierPrime(color: scanColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text("STATUS: $regionName", style: GoogleFonts.courierPrime(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ANIMATION HELPERS (Radar, Scanner, Grid)
class PulsingRadar extends StatefulWidget {
  final Color color;
  const PulsingRadar({super.key, required this.color});
  @override
  State<PulsingRadar> createState() => _PulsingRadarState();
}
class _PulsingRadarState extends State<PulsingRadar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Stack(alignment: Alignment.center, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: widget.color, blurRadius: 6)])),
        Container(width: 8 + (_controller.value * 30), height: 8 + (_controller.value * 30), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.color.withOpacity(1 - _controller.value), width: 2))),
      ]),
    );
  }
}
class ScannerAnimation extends StatefulWidget {
  final Color color;
  const ScannerAnimation({super.key, required this.color});
  @override
  State<ScannerAnimation> createState() => _ScannerAnimationState();
}
class _ScannerAnimationState extends State<ScannerAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, child) => CustomPaint(painter: ScannerPainter(progress: _controller.value, color: widget.color)));
  }
}
class ScannerPainter extends CustomPainter {
  final double progress; final Color color; ScannerPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withOpacity(0), color, color.withOpacity(0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))..strokeWidth = 2;
    canvas.drawLine(Offset(size.width * progress, 0), Offset(size.width * progress, size.height), linePaint);
  }
  @override bool shouldRepaint(ScannerPainter oldDelegate) => true;
}
class GridOverlayPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.white.withOpacity(0.1)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}