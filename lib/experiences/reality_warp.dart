import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RealityWarp extends StatefulWidget {
  final bool active;
  const RealityWarp({super.key, required this.active});

  @override
  State<RealityWarp> createState() => _RealityWarpState();
}

class _RealityWarpState extends State<RealityWarp> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  Offset _touchPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) {
        setState(() {
          _touchPos = d.localPosition;
        });
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Pattern
            Image.network(
              "https://www.transparenttextures.com/patterns/cubes.png", 
              fit: BoxFit.cover,
              color: Colors.grey.shade800,
              colorBlendMode: BlendMode.modulate,
              errorBuilder: (_,__,___) => const SizedBox(),
            ),
            
            // Warp Effect Layer 1
            AnimatedBuilder(
              animation: _anim,
              builder: (context, child) {
                 return ShaderMask(
                   shaderCallback: (bounds) {
                     return RadialGradient(
                       center: Alignment(
                         (_touchPos.dx / bounds.width) * 2 - 1,
                         (_touchPos.dy / bounds.height) * 2 - 1,
                       ),
                       radius: 0.5 + (_anim.value * 0.2), // Pulse
                       colors: const [Colors.transparent, Colors.deepPurple, Colors.transparent],
                       stops: const [0.3, 0.5, 1.0],
                       tileMode: TileMode.mirror,
                     ).createShader(bounds);
                   },
                   blendMode: BlendMode.difference, // Trippy effect
                   child: Container(
                     decoration: const BoxDecoration(
                       gradient: LinearGradient(
                         colors: [Colors.cyan, Colors.purpleAccent],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight
                       )
                     ),
                   ),
                 );
              },
            ),
            
             // Warp Effect Layer 2 (Interference)
            AnimatedBuilder(
              animation: _anim,
              builder: (context, child) {
                 return ShaderMask(
                   shaderCallback: (bounds) {
                     return SweepGradient(
                       center: Alignment(
                         (_touchPos.dx / bounds.width) * 2 - 1,
                         (_touchPos.dy / bounds.height) * 2 - 1,
                       ),
                       startAngle: _anim.value * 6.28,
                       endAngle: _anim.value * 6.28 + 3.14,
                       colors: const [Colors.yellowAccent, Colors.transparent],
                     ).createShader(bounds);
                   },
                   blendMode: BlendMode.plus, 
                   child: Container(color: Colors.white10),
                 );
              },
            ),

            Center(
               child: IgnorePointer(
                 child: Text(
                   "TOUCH THE VOID",
                   style: GoogleFonts.monoton(
                     color: Colors.white54,
                     fontSize: 32,
                   ),
                 ),
               ),
            ),
          ],
        ),
      ),
    );
  }
}
