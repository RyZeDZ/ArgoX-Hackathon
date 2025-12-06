import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'map_data.dart';
import 'result.dart';
import 'algeria_data.dart'; // Coordinate mapping
import 'ranking.dart'; 

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isLoading = false;

  bool _isCrossBreedingMode = true;

  // Mutable variables (Can be changed by typing or selecting)
  String? _selectedParentA = 'Ceanothus';
  String? _selectedParentB = 'Pomaderris';

  static const Color _accentGreen = Color(0xFF2ECC71);
  static const Color _glassDark = Color(0x0DFFFFFF);

  final List<String> _plantOptions = [
    "Ceanothus",
    "Pomaderris",
    "Ulex",
    "Lotus",
    "Lathyrus",
    "Astragalus",
    "Pisum",
    "Vicia",
    "Trifolium",
    "Pratia",
    "Plantago",
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/green.mp4')
      ..initialize().then((_) {
        setState(() => _isVideoInitialized = true);
        _videoController.setLooping(true);
        _videoController.setVolume(0.0);
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  // --- CONNECTING TO BACKEND ---
  Future<void> _runAnalysis() async {
    // 1. INPUT VALIDATION
    if (_selectedParentA == null || _selectedParentA!.isEmpty) {
      _showError("Please enter or select Parent A");
      return;
    }
    if (_isCrossBreedingMode && (_selectedParentB == null || _selectedParentB!.isEmpty)) {
      _showError("Please enter or select Parent B");
      return;
    }

    setState(() => _isLoading = true);

    const String baseUrl = "http://10.30.104.113:8000";

    final String endpoint = _isCrossBreedingMode
            ? "$baseUrl/api/predict/"
            : "$baseUrl/api/predict-single/";

    Map<String, dynamic> requestBody = _isCrossBreedingMode
            ? {"plant_a": _selectedParentA, "plant_b": _selectedParentB}
            : {"plant": _selectedParentA};

    try {
      print("Sending request to: $endpoint");

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> stateNames = data['States'] ?? [];
        List<MapZone> parsedZones = [];

        bool isCompatible = data['Compatible'] == true;

        for (var state in stateNames) {
          String stateStr = state.toString();
          if (algeriaStatesCoords.containsKey(stateStr)) {
            parsedZones.add(
              MapZone(
                coordinates: algeriaStatesCoords[stateStr]!,
                color: (isCompatible || !_isCrossBreedingMode)
                        ? _accentGreen
                        : Colors.redAccent,
                radius: 40.0,
                label: stateStr,
              ),
            );
          }
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                isCrossBreedingMode: _isCrossBreedingMode,
                crossBreedingResult: data,
                showGenusResults: !_isCrossBreedingMode,
                activeZones: parsedZones,
                mapRegionName: data['Zone']?.toString().toUpperCase() ?? "ANALYSIS DONE",
              ),
            ),
          );
        }
      } else {
        _showError("Server Error: ${response.statusCode}\nBody: ${response.body}");
      }
    } catch (e) {
      _showError("Connection Failed.\nError: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _toggleMode(String modeText) {
    setState(() {
      _isCrossBreedingMode = (modeText == "Cross-Breeding Simulator");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(color: Colors.transparent),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildHeroSection(),
                  const SizedBox(height: 32),
                  _buildInputCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: const BoxDecoration(
                color: _accentGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "AgroX Intelligence",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        IconButton(
  icon: const Icon(Icons.leaderboard, color: Colors.white70),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RankingScreen()), // Replace 'Ranking' with the actual class name inside ranking.dart
    );
  },
),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isCrossBreedingMode
              ? "Hybridization\nForecasting"
              : "Genus\nOptimization",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 36,
            height: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Autonomous AI system predicting plant pair\ncompatibility via genomic analysis.",
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleButton("Single Genus", !_isCrossBreedingMode),
              _buildToggleButton("Cross-Breeding Simulator", _isCrossBreedingMode),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isActive) {
    return GestureDetector(
      onTap: () => _toggleMode(text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _accentGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isActive ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _glassDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCrossBreedingMode ? "Plant Pair Engine" : "Genus Analyzer",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          if (_isCrossBreedingMode)
            Row(
              children: [
                Expanded(
                  child: _buildComboField(
                    label: "Parent A",
                    initialValue: _selectedParentA,
                    onChanged: (val) => setState(() => _selectedParentA = val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildComboField(
                    label: "Parent B",
                    initialValue: _selectedParentB,
                    onChanged: (val) => setState(() => _selectedParentB = val),
                  ),
                ),
              ],
            )
          else
            _buildComboField(
              label: "Target Genus",
              initialValue: _selectedParentA,
              onChanged: (val) => setState(() => _selectedParentA = val),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _runAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(
                      "Analyze",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- THE NEW "TYPE OR SELECT" WIDGET ---
  Widget _buildComboField({
    required String label,
    required String? initialValue,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return Autocomplete<String>(
              initialValue: TextEditingValue(text: initialValue ?? ''),
              
              // 1. FILTERING LOGIC
              optionsBuilder: (TextEditingValue textEditingValue) {
                // IF EMPTY: Show all options (acts like a dropdown)
                if (textEditingValue.text == '') {
                  return _plantOptions;
                }
                // IF TYPING: Filter the list
                return _plantOptions.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },

              // 2. WHEN SELECTED
              onSelected: (String selection) {
                onChanged(selection);
              },

              // 3. THE INPUT BOX (Designed to look like a Dropdown)
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged, // Updates variable as you type
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 14),
                    // Dropdown Arrow Icon
                    suffixIcon: const Icon(
                      Icons.arrow_drop_down,
                      color: _accentGreen,
                      size: 24,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _accentGreen, width: 1),
                    ),
                  ),
                );
              },

              // 4. THE DROPDOWN LIST STYLE
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: const Color(0xFF1E1E1E),
                    elevation: 10,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: 200,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                              child: Text(
                                option,
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}