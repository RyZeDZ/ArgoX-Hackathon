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
  // Ensure this IP is reachable from your emulator/device
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
          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI: Header ---
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

  // --- UI: Body List ---
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentGreen),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchRankings,
                style: ElevatedButton.styleFrom(backgroundColor: _accentGreen),
                child: const Text("Retry", style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
      );
    }

    if (_rankings.isEmpty) {
      return Center(
        child: Text(
          "No rankings available yet.",
          style: GoogleFonts.spaceGrotesk(color: Colors.white54),
        ),
      );
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

  // --- UI: Individual Rank Card ---
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
            // Rank Number
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
            // Plant Names
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
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Score
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
                Text(
                  "Potential",
                  style: GoogleFonts.inter(
                    color: _accentGreen.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC & UI: Detail Modal Window ---
  void _showMatchDetails(BuildContext context, dynamic item) {
    final String p1 = item['Plant_A'] ?? 'Unknown';
    final String p2 = item['Plant_B'] ?? 'Unknown';
    final String zone = item['Zone'] ?? 'Unknown';
    final String scoreStr = item['Score'].toString();
    final double scoreVal = double.tryParse(scoreStr) ?? 0.0;

    // Get explanation from API or use fallback
    final String explanation = item['Explanation'] ?? 
        _generateFallbackExplanation(p1, p2, scoreVal);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allows sheet to be taller
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75, // 75% height
            decoration: const BoxDecoration(
              color: Color(0xFF0F2027), 
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(top: BorderSide(color: Colors.white24, width: 1)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  width: 40, 
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Center(
                          child: Text(
                            "HYBRID REPORT",
                            style: GoogleFonts.spaceGrotesk(
                              color: _accentGreen,
                              fontSize: 14,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Plant Names Visual
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: _buildPlantAvatar(p1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(Icons.add_circle_outline, color: _accentGreen.withOpacity(0.5)),
                            ),
                            Expanded(child: _buildPlantAvatar(p2)),
                          ],
                        ),
                        
                        const SizedBox(height: 30),

                        // Score Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _glassDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _accentGreen.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Compatibility Score", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$scoreStr%",
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 60,
                                width: 60,
                                child: CircularProgressIndicator(
                                  value: scoreVal / 100,
                                  backgroundColor: Colors.white10,
                                  color: _accentGreen,
                                  strokeWidth: 6,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Explanation / AI Analysis Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: _gold, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    "AI ANALYSIS",
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                explanation,
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Details Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildDetailBox(Icons.public, "Zone", zone),
                            _buildDetailBox(Icons.water_drop, "Watering", "Moderate"),
                            _buildDetailBox(Icons.wb_sunny, "Sunlight", "High"), 
                            _buildDetailBox(Icons.spa, "Growth", "Fast"), 
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

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
                    child: Text(
                      "Close Report", 
                      style: GoogleFonts.spaceGrotesk(color: Colors.black, fontWeight: FontWeight.bold)
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helper Widgets & Functions ---

  Widget _buildPlantAvatar(String name) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white10,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "?", 
            style: GoogleFonts.spaceGrotesk(color: _accentGreen, fontSize: 20, fontWeight: FontWeight.bold)
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDetailBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
                Text(value, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _generateFallbackExplanation(String p1, String p2, double score) {
    if (score >= 80) {
      return "These two plants exhibit excellent genetic compatibility. The combined traits likely result in higher drought resistance and improved growth rates in the selected zone.";
    } else if (score >= 50) {
      return "A moderate match. While $p1 provides good structural integrity, $p2 might struggle with the nutrient requirements. Supplemental care may be required.";
    } else {
      return "Low compatibility detected. The environmental needs of $p1 conflict significantly with $p2, likely resulting in poor germination or weak root systems.";
    }
  }
}