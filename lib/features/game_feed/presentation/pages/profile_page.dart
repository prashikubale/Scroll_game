import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/game_session.dart';
import '../providers/game_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(gameSessionsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Brain Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: sessionsAsync.when(
        data: (sessions) => _buildBody(context, sessions),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<GameSession> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              "No data yet.\nPlay some games to build your profile.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Calculate Stats
    final Map<String, double> stats = _calculateStats(sessions);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar / Header
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            "Cognitive Metrics",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${sessions.length} Sessions Recorded",
            style: GoogleFonts.poppins(color: Colors.white54),
          ),
          const SizedBox(height: 48),

          // Radar Chart
          SizedBox(
            height: 300,
            width: 300,
            child: CustomPaint(
              painter: RadarChartPainter(
                stats: stats,
                lineColor: Colors.deepPurpleAccent,
                fillColor: Colors.deepPurple.withOpacity(0.3),
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Recent Activity
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Recent Activity",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: min(5, sessions.length),
            itemBuilder: (context, index) {
              // Show newest first
              final session = sessions[sessions.length - 1 - index];
              return Card(
                color: Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.videogame_asset, color: Colors.deepPurpleAccent),
                  title: Text(
                    session.gameId, // In real app, map ID to Name
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  trailing: Text(
                    "${session.score} pts",
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _formatDate(session.timestamp),
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  Map<String, double> _calculateStats(List<GameSession> sessions) {
    // This is a mock calculation. 
    // In a real app, we'd map gameIds to specific attributes (Memory, Reaction, etc.)
    // For now, we generate pseudo-consistent values based on the number of sessions and scores.
    
    double totalScore = sessions.fold(0, (sum, s) => sum + s.score);
    double avgScore = totalScore / sessions.length;
    
    // Normalize avgScore (assuming 0-100 scale for visual simplicity, clamping 0.0-1.0)
    double performance = (avgScore / 100).clamp(0.2, 1.0);
    
    return {
      "Focus": (performance * 0.9).clamp(0.0, 1.0),
      "Reaction": (performance * 1.1).clamp(0.0, 1.0),
      "Memory": (performance * 0.8 + 0.1).clamp(0.0, 1.0),
      "Precision": (performance).clamp(0.0, 1.0),
      "Speed": (performance * 1.05).clamp(0.0, 1.0),
    };
  }
}

class RadarChartPainter extends CustomPainter {
  final Map<String, double> stats;
  final Color lineColor;
  final Color fillColor;

  RadarChartPainter({
    required this.stats,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final keys = stats.keys.toList();
    final angleStep = (2 * pi) / keys.length;

    final paintLine = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final paintBorder = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Draw Webs
    for (int i = 1; i <= 4; i++) {
      double r = radius * (i / 4);
      _drawPolygon(canvas, center, r, keys.length, angleStep, paintLine);
    }

    // Draw Stats Polygon
    Path path = Path();
    List<Offset> points = [];

    for (int i = 0; i < keys.length; i++) {
      double value = stats[keys[i]]!; // 0.0 to 1.0
      double r = radius * value;
      double angle = -pi / 2 + (i * angleStep); // Start from top
      double x = center.dx + r * cos(angle);
      double y = center.dy + r * sin(angle);
      Offset p = Offset(x, y);
      points.push(p);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintBorder);

    // Draw Labels & Dots
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < keys.length; i++) {
      double angle = -pi / 2 + (i * angleStep);
      
      // Label Position (outside)
      double labelR = radius + 20;
      double lx = center.dx + labelR * cos(angle);
      double ly = center.dy + labelR * sin(angle);

      textPainter.text = TextSpan(
        text: keys[i],
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(lx - textPainter.width / 2, ly - textPainter.height / 2));
    }
  }
  
  void _drawPolygon(Canvas canvas, Offset center, double radius, int sides, double angleStep, Paint paint) {
    Path path = Path();
    for (int i = 0; i < sides; i++) {
      double angle = -pi / 2 + (i * angleStep);
      double x = center.dx + radius * cos(angle);
      double y = center.dy + radius * sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

extension on List {
  void push(dynamic item) => add(item);
}
