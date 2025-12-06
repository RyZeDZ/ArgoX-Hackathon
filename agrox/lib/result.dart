import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'map_data.dart'; 
// import 'ranking.dart'; // <--- REMOVED: No longer needed here

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
  static const Color _glassDark = Color(0x0DFFFFFF);

  @override
  Widget build(BuildContext context) {
    // Determine if we should show the map
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
        // <--- REMOVED: The actions[] block containing the menu icon is gone
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

  // ... [The rest of your widgets (_buildCrossBreedingResults, etc.) remain exactly the same] ...
  
  // ==========================================
  // 1. CROSS-BREEDING RESULT WIDGET
  // ==========================================
  Widget _buildCrossBreedingResults() {
    final bool isCompatible = crossBreedingResult['Compatible'] == true;
    final double score = (crossBreedingResult['Score'] ?? 0).toDouble();
    final double futureScore = (crossBreedingResult['Future_Score'] ?? 0).toDouble();
    final String resilience = crossBreedingResult['Resilience'] ?? "N/A";
    final String explanation = crossBreedingResult['Explanation'] ?? "No details.";
    final String zone = crossBreedingResult['Zone'] ?? "Unknown";

    final Map<String, dynamic> traits = crossBreedingResult['Traits'] ?? {};
    final String drought = traits['Drought_Tol']?.toString() ?? "Medium";
    final String salinity = traits['Salinity_Tol']?.toString() ?? "Low";
    final String maturity = traits['Growth_Speed']?.toString() ?? "Average"; 
    final String disease = traits['Disease_Res']?.toString() ?? "Standard"; 

    final Color statusColor = isCompatible ? _accentGreen : _accentRed;

    return Column(
      children: [
        // BOX A: MAIN SCORE
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
                              color: Colors.white70, fontSize: 16)),
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
              _buildSimpleRow("Future Viability", "${futureScore.toStringAsFixed(1)}%", true),
              const SizedBox(height: 12),
              _buildSimpleRow("Resilience Score", resilience, isCompatible),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // BOX B: DETAILED REPORT
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Analysis Report",
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompatible ? _accentGreen.withOpacity(0.1) : _accentRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text(zone,
                      style: GoogleFonts.inter(
                          color: isCompatible ? _accentGreen : _accentRed,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildTraitRow("Drought Tolerance", drought),
              _buildTraitRow("Salinity Tolerance", salinity),
              _buildTraitRow("Earliness / Maturity", maturity),
              _buildTraitRow("Disease Resistance", disease),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              
              Text(explanation,
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 13, height: 1.5),
              )
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
    final String inputPlant = crossBreedingResult['Plant_A'] ?? "Unknown";
    final String bestMatch = crossBreedingResult['Best_Match'] ?? "Vicia";
    final double score = (crossBreedingResult['Score'] ?? 0).toDouble();
    final String explanation = crossBreedingResult['Explanation'] ?? "Analysis complete.";

    final Map<String, dynamic> traits = crossBreedingResult['Traits'] ?? {};
    final String drought = traits['Drought_Tol']?.toString() ?? "High";
    final String salinity = traits['Salinity_Tol']?.toString() ?? "Medium";
    final String maturity = traits['Growth_Speed']?.toString() ?? "Early"; 
    final String disease = traits['Disease_Res']?.toString() ?? "Resistant";

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "GENUS OPTIMIZATION",
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const Icon(Icons.hub, color: _accentGreen, size: 20),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("INPUT", style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          inputPlant,
                          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.compare_arrows, color: _accentGreen.withOpacity(0.6), size: 28),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("BEST MATCH", style: GoogleFonts.inter(color: _accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          bestMatch,
                          style: GoogleFonts.spaceGrotesk(color: _accentGreen, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

              Center(
                child: Column(
                  children: [
                    Text(
                      "${score.toStringAsFixed(1)}%",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Hybridization Potential",
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

              Text(
                "ANALYSIS REPORT",
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTraitRow("Drought Tolerance", drought),
                    _buildTraitRow("Salinity Tolerance", salinity),
                    _buildTraitRow("Earliness / Maturity", maturity),
                    _buildTraitRow("Disease Resistance", disease),
                    
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),
                    
                    Text(
                      explanation,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildTraitRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "• $label",
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: _accentGreen,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleRow(String label, String val, bool isGood) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)), 
      Text(val, style: GoogleFonts.inter(color: isGood ? _accentGreen : _accentRed, fontSize: 14, fontWeight: FontWeight.w600))
    ]);
  }
}

// ==========================================
// SATELLITE MAP WIDGETS
// ==========================================
class SatelliteMapWidget extends StatelessWidget {
  final List<MapZone> zones;
  final String regionName;
  const SatelliteMapWidget({super.key, required this.zones, required this.regionName});

  @override
  Widget build(BuildContext context) {
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