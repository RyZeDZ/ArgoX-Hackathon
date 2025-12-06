import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  // --- Constants & Theme ---
  static const Color _accentGreen = Color(0xFF2ECC71);
  static const Color _glassDark = Color(0x0DFFFFFF);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _silver = Color(0xFFC0C0C0);
  static const Color _bronze = Color(0xFFCD7F32);
  
  // --- API Configuration ---
  static const String baseUrl = "http://10.30.104.113:8000"; 
  final bool _isCrossBreedingMode = true; 

  // --- State Variables ---
  List<dynamic> _rankings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchRankings();
  }

  // --- API Call ---
  Future<void> fetchRankings() async {
    final String endpoint = _isCrossBreedingMode
        ? "$baseUrl/api/ranks/"
        : "$baseUrl/api/standard-ranking/";

    try {
      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _rankings = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load rankings: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error: $e";
        _isLoading = false;
      });
    }
  }

  // --- UI: Main Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [Color(0xFF0F2027), Colors.black],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "HYBRID RANKING",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const Icon(Icons.emoji_events, color: _accentGreen),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accentGreen));
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)));
    }
    if (_rankings.isEmpty) {
      return const Center(child: Text("No rankings available yet.", style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _rankings.length,
      itemBuilder: (context, index) {
        final item = _rankings[index];
        return _buildRankCard(index + 1, item);
      },
    );
  }

  Widget _buildRankCard(int rank, dynamic item) {
    Color rankColor;
    if (rank == 1) rankColor = _gold;
    else if (rank == 2) rankColor = _silver;
    else if (rank == 3) rankColor = _bronze;
    else rankColor = Colors.white24;

    final String p1 = item['Plant_A'] ?? 'Unknown';
    final String p2 = item['Plant_B'] ?? 'Unknown';
    final String zone = item['Zone'] ?? 'Unknown';
    final String score = item['Score'].toString();

    return GestureDetector(
      onTap: () => _showMatchDetails(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _glassDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            if (rank <= 3)
              BoxShadow(
                color: rankColor.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: rankColor.withOpacity(0.5)),
                color: rankColor.withOpacity(0.1),
              ),
              child: Text(
                "#$rank",
                style: GoogleFonts.spaceGrotesk(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$p1 + $p2",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    zone,
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$score%",
                  style: GoogleFonts.spaceGrotesk(
                    color: _accentGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // UPDATED DETAIL MODAL
  // ==========================================
  void _showMatchDetails(BuildContext context, dynamic item) {
    // 1. EXTRACT DATA SAFELY
    final String p1 = item['Plant_A'] ?? '?';
    final String p2 = item['Plant_B'] ?? '?';
    final String zone = item['Zone'] ?? 'Unknown';
    final String resilience = item['Resilience'] ?? 'Unknown';
    final String explanation = item['Explanation'] ?? 'No analysis available.';
    
    // Scores
    final double score = double.tryParse(item['Score']?.toString() ?? '0') ?? 0.0;
    final double futureScore = double.tryParse(item['Future_Score']?.toString() ?? '0') ?? 0.0;
    
    // Maps
    final Map<String, dynamic> traits = item['Traits'] ?? {};
    final Map<String, dynamic> agronomics = item['Agronomics'] ?? {};
    final List<dynamic> states = item['States'] ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85, 
            decoration: const BoxDecoration(
              color: Color(0xFF0F2027), 
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(top: BorderSide(color: Colors.white24, width: 1)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0), // Bottom padding handled by scrollView
            child: Column(
              children: [
                // Drag Handle
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Plants
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildPlantAvatar(p1),
                            Icon(Icons.add_circle_outline, color: _accentGreen.withOpacity(0.5)),
                            _buildPlantAvatar(p2),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // 1. SCORES (Current & Future)
                        Row(
                          children: [
                            Expanded(child: _buildScoreBox("Compatibility", score, _accentGreen)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildScoreBox("Future Forecast", futureScore, const Color(0xFF3498DB))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 2. RESILIENCE & ZONE
                        Row(
                          children: [
                            Expanded(child: _buildInfoBadge(Icons.shield, "Resilience", resilience)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInfoBadge(Icons.public, "Zone", zone)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 3. TRAITS (Progress Bars)
                        Text("GENETIC TRAITS", style: _headerStyle),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: _cardDecoration,
                          child: Column(
                            children: [
                              _buildTraitBar("Drought Tolerance", traits['Drought_Tol']),
                              const SizedBox(height: 16),
                              _buildTraitBar("Growth Speed", traits['Growth_Speed']),
                              const SizedBox(height: 16),
                              _buildTraitBar("Salinity Tolerance", traits['Salinity_Tol']),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4. AGRONOMICS (Grid)
                        Text("AGRONOMICS", style: _headerStyle),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildDetailBox(Icons.water_drop, "Water Usage", agronomics['Water_Usage'] ?? 'N/A'),
                            _buildDetailBox(Icons.shower, "Irrigation", agronomics['Irrigation_Strategy'] ?? 'N/A'),
                            _buildDetailBox(Icons.coronavirus, "Disease Risk", agronomics['Disease_Pressure'] ?? 'N/A'),
                            _buildDetailBox(Icons.warning_amber, "Pathogen Alert", agronomics['Pathogen_Alert'] ?? 'None'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 5. EXPLANATION
                        Text("AI ANALYSIS", style: _headerStyle),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: _cardDecoration,
                          child: Text(
                            explanation,
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 6. STATES
                        if (states.isNotEmpty) ...[
                          Text("RECOMMENDED STATES", style: _headerStyle),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: states.map((s) => Chip(
                              backgroundColor: Colors.white10,
                              label: Text(s.toString(), style: GoogleFonts.inter(color: const Color.fromARGB(255, 44, 36, 36), fontSize: 12)),
                              avatar: const Icon(Icons.location_on, size: 14, color: _accentGreen),
                            )).toList(),
                          ),
                        ],
                        
                        const SizedBox(height: 40),
                        
                        // Close Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text("Close Report", style: GoogleFonts.spaceGrotesk(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HELPER STYLES & WIDGETS ---

  TextStyle get _headerStyle => GoogleFonts.spaceGrotesk(
    color: Colors.white54, 
    fontSize: 12, 
    fontWeight: FontWeight.bold, 
    letterSpacing: 1.5
  );

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white10),
  );

  Widget _buildPlantAvatar(String name) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white10,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "?", 
            style: GoogleFonts.spaceGrotesk(color: _accentGreen, fontSize: 18, fontWeight: FontWeight.bold)
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildScoreBox(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _glassDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 4),
          Text("${value.toStringAsFixed(1)}%", style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: value / 100, color: color, backgroundColor: Colors.white10, minHeight: 4),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
                Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitBar(String label, dynamic value) {
    double val = double.tryParse(value.toString()) ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
            Text("${val.toStringAsFixed(0)}%", style: GoogleFonts.inter(color: _accentGreen, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
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

  Widget _buildDetailBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
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
                Text(value, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }
}