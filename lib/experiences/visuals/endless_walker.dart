import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class EndlessWalker extends StatefulWidget {
  final bool active;
  const EndlessWalker({super.key, required this.active});

  @override
  State<EndlessWalker> createState() => _EndlessWalkerState();
}

class _EndlessWalkerState extends State<EndlessWalker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _NightWalkerPainter(_controller.value),
                size: Size.infinite,
              );
            },
          ),
        ),

        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 1.3,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "NIGHT WALK",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.3),
                letterSpacing: 8,
                fontWeight: FontWeight.w200,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NightWalkerPainter extends CustomPainter {
  final double animationValue;
  double get time => DateTime.now().millisecondsSinceEpoch / 1000.0;

  _NightWalkerPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    _drawNightSky(canvas, size);
    _drawCityscape(canvas, size);
    _drawGround(canvas, size);
    _drawRealisticHuman(canvas, size);
  }

  void _drawNightSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A0D1E), Color(0xFF181D32), Color(0xFF242840)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Moon
    final moonPos = Offset(size.width * 0.7, size.height * 0.2);
    canvas.drawCircle(
      moonPos,
      30,
      Paint()
        ..color = Color(0xFFE8D5B7).withOpacity(0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawCircle(moonPos, 15, Paint()..color = Color(0xFFE8D5B7));

    // Stars
    final rnd = Random(42);
    for (int i = 0; i < 60; i++) {
      double x = rnd.nextDouble() * size.width;
      double y = rnd.nextDouble() * size.height * 0.5;
      double s = 0.5 + rnd.nextDouble();
      double twinkle = sin(time * 2 + i) * 0.2 + 0.8;
      canvas.drawCircle(
        Offset(x, y),
        s,
        Paint()..color = Colors.white.withOpacity(0.4 * twinkle),
      );
    }
  }

  void _drawCityscape(Canvas canvas, Size size) {
    final groundY = size.height * 0.78;
    final rnd = Random(123);
    double x = 0;

    while (x < size.width) {
      double w = 30 + rnd.nextDouble() * 60;
      double h = 60 + rnd.nextDouble() * 120;

      canvas.drawRect(
        Rect.fromLTWH(x, groundY - h, w, h),
        Paint()..color = Color(0xFF0B0E18),
      );

      for (int i = 0; i < 3; i++) {
        if (rnd.nextDouble() > 0.7) {
          canvas.drawRect(
            Rect.fromLTWH(
              x + 3 + rnd.nextDouble() * (w - 8),
              groundY - h + 6 + rnd.nextDouble() * (h - 12),
              2.5,
              4,
            ),
            Paint()..color = Color(0xFFFFE4A3).withOpacity(0.6),
          );
        }
      }
      x += w + 3;
    }
  }

  void _drawGround(Canvas canvas, Size size) {
    final groundY = size.height * 0.78;
    final groundRect = Rect.fromLTWH(
      0,
      groundY,
      size.width,
      size.height - groundY,
    );
    canvas.drawRect(
      groundRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF161925), Color(0xFF0D0F16)],
        ).createShader(groundRect),
    );

    final cx = size.width / 2;

    // Light pool
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY + 15), width: 160, height: 45),
      Paint()
        ..color = Color(0xFFFFE4A3).withOpacity(0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Streetlights
    for (double i = -220; i <= 220; i += 120) {
      double x = cx + i;
      canvas.drawLine(
        Offset(x, groundY - 70),
        Offset(x, groundY),
        Paint()
          ..color = Color(0xFF222530)
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(
        Offset(x, groundY - 70),
        3,
        Paint()..color = Color(0xFFFFE4A3).withOpacity(0.7),
      );
      canvas.drawCircle(
        Offset(x, groundY - 70),
        8,
        Paint()
          ..color = Color(0xFFFFE4A3).withOpacity(0.12)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  void _drawRealisticHuman(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final groundY = size.height * 0.78;
    final t = animationValue;

    // Natural motion
    final bob = sin(t * pi * 4) * 1.5;
    final sway = sin(t * pi * 2) * 2.0;

    final hipAvgY = groundY - 56;
    final hipY = hipAvgY + bob;
    final spineTopY = hipY - 40;

    // Solve limbs
    final lLeg = _solveLeg2D(t, isLeft: true);
    final rLeg = _solveLeg2D(t, isLeft: false);
    final lArm = _solveArm2D(t, isLeft: true);
    final rArm = _solveArm2D(t, isLeft: false);

    // Body structure
    double hipW = 13.0;
    double shldrW = 24.0;

    final root = vm.Vector3(sway * 0.2, hipY, 0);
    final chest = vm.Vector3(sway * 0.15, spineTopY + 5, 0);
    final neck = vm.Vector3(sway * 0.1, spineTopY - 3, 0);
    final headCenter = vm.Vector3(sway * 0.1, spineTopY - 22, 0);

    final lHip = vm.Vector3(sway * 0.2, hipY, hipW / 2);
    final rHip = vm.Vector3(sway * 0.2, hipY, -hipW / 2);
    final lShldr = vm.Vector3(sway * 0.15, spineTopY, shldrW / 2);
    final rShldr = vm.Vector3(sway * 0.15, spineTopY, -shldrW / 2);

    final lKnee = lHip + vm.Vector3(lLeg.knee.dx, lLeg.knee.dy, 0);
    final lAnkle = lHip + vm.Vector3(lLeg.foot.dx, lLeg.foot.dy, 0);
    final rKnee = rHip + vm.Vector3(rLeg.knee.dx, rLeg.knee.dy, 0);
    final rAnkle = rHip + vm.Vector3(rLeg.foot.dx, rLeg.foot.dy, 0);

    final lElbow = lShldr + vm.Vector3(lArm.knee.dx, lArm.knee.dy, 0);
    final lHand = lShldr + vm.Vector3(lArm.foot.dx, lArm.foot.dy, 0);
    final rElbow = rShldr + vm.Vector3(rArm.knee.dx, rArm.knee.dy, 0);
    final rHand = rShldr + vm.Vector3(rArm.foot.dx, rArm.foot.dy, 0);

    // Camera
    double camRotY = pi * 0.18 + sin(t * pi * 2) * 0.1;
    final rotMat = vm.Matrix4.rotationY(camRotY);
    rotMat.multiply(vm.Matrix4.rotationX(-0.05));

    List<_BodyPart> parts = [];

    // Colors
    final cSkin = Color(0xFFD2A679);
    final cJeans = Color(0xFF2A3D4F);
    final cShirt = Color(0xFF1A2230);
    final cShoes = Color(0xFF2B3E50);
    final cHair = Color(0xFF281A12);

    void addLimb(vm.Vector3 p1, vm.Vector3 p2, double r1, double r2, Color c) {
      parts.add(_BodyPart(p1, p2, r1, r2, c, isSphere: false));
    }

    void addJoint(vm.Vector3 p, double r, Color c) {
      parts.add(_BodyPart(p, null, r, 0, c, isSphere: true));
    }

    // LEGS
    addLimb(lHip, lKnee, 7.0, 6.2, cJeans);
    addLimb(rHip, rKnee, 7.0, 6.2, cJeans);
    addJoint(lKnee, 5.8, cJeans);
    addJoint(rKnee, 5.8, cJeans);
    addLimb(lKnee, lAnkle, 5.8, 4.5, cJeans);
    addLimb(rKnee, rAnkle, 5.8, 4.5, cJeans);

    // SHOES
    void addShoe(vm.Vector3 ankle, double angle) {
      final toe = ankle + vm.Vector3(cos(angle) * 12, sin(angle) * 12, 0);
      addLimb(ankle, toe, 4.5, 4.0, cShoes);
    }

    addShoe(lAnkle, lLeg.footAngle);
    addShoe(rAnkle, rLeg.footAngle);

    // TORSO
    addLimb(lHip, rHip, 7.5, 7.5, cJeans);
    addLimb(root, chest, 8.5, 10.5, cShirt);
    addLimb(lShldr, rShldr, 6.5, 6.5, cShirt);

    // ARMS
    addLimb(lShldr, lElbow, 5.8, 5.0, cShirt);
    addLimb(rShldr, rElbow, 5.8, 5.0, cShirt);
    addJoint(lElbow, 4.5, cSkin);
    addJoint(rElbow, 4.5, cSkin);
    addLimb(lElbow, lHand, 4.2, 3.5, cSkin);
    addLimb(rElbow, rHand, 4.2, 3.5, cSkin);
    addJoint(lHand, 3.8, cSkin);
    addJoint(rHand, 3.8, cSkin);

    // NECK & HEAD
    addLimb(chest, neck, 5.0, 4.8, cSkin);
    addLimb(neck, headCenter + vm.Vector3(0, 2, 0), 4.8, 5.2, cSkin);

    final topHead = headCenter + vm.Vector3(0, -7, 0);
    addLimb(headCenter + vm.Vector3(0, 1, 0), topHead, 7.5, 7.8, cSkin);

    // Eyes
    final facePos = headCenter + vm.Vector3(2.5, -1.5, 0);
    addJoint(facePos + vm.Vector3(0, 0, 1.8), 1.0, Color(0xFF1A1A1A));
    addJoint(facePos + vm.Vector3(0, 0, -1.8), 1.0, Color(0xFF1A1A1A));

    // Hair (simple flowing strands)
    final hairBase = headCenter + vm.Vector3(-3, -2, 0);
    for (int i = 0; i < 5; i++) {
      final offset = vm.Vector3(
        -2 - i * 1.5 + sin(t * 8 + i) * 1.5,
        3 + i * 2.5,
        (i - 2) * 0.8,
      );
      addLimb(hairBase, hairBase + offset, 2.5, 1.8, cHair);
    }

    // Transform & sort
    for (var p in parts) {
      p.transform(rotMat, cx, 0);
    }
    parts.sort((a, b) => a.z.compareTo(b.z));

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + sway * 0.2, groundY + 3),
        width: 50,
        height: 16,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7),
    );

    // Draw
    for (var p in parts) {
      p.draw(canvas);
    }
  }

  _LimbResult _solveLeg2D(double t, {required bool isLeft}) {
    const strideLen = 78.0;
    const legLen1 = 28.0;
    const legLen2 = 28.0;

    double tLeg = isLeft ? (t + 0.5) % 1.0 : t;
    Offset targetFoot;
    double footAngle = 0;

    if (tLeg < 0.5) {
      final p = tLeg / 0.5;
      targetFoot = Offset(
        (strideLen / 2) - p * strideLen,
        56 - sin(t * pi * 4) * 1.2,
      );
      footAngle = (p - 0.5) * 0.6;
    } else {
      final p = (tLeg - 0.5) / 0.5;
      double lift = sin(p * pi) * 20;
      targetFoot = Offset(
        -(strideLen / 2) + p * strideLen,
        56 - lift - sin(t * pi * 4) * 1.2,
      );
      footAngle = 0.3 - p * 0.6;
    }

    final knee = _solveIK2D(Offset.zero, targetFoot, legLen1, legLen2);
    return _LimbResult(knee: knee, foot: targetFoot, footAngle: footAngle);
  }

  _LimbResult _solveArm2D(double t, {required bool isLeft}) {
    double tArm = isLeft ? t : (t + 0.5) % 1.0;
    final angle = sin(tArm * pi * 2) * 0.55;
    final elbow = Offset(sin(angle) * 22, cos(angle) * 22);
    final forearmAngle = angle + 0.4 + sin(t * pi * 2 - 0.8) * 0.18;
    final hand = elbow + Offset(sin(forearmAngle) * 20, cos(forearmAngle) * 20);
    return _LimbResult(knee: elbow, foot: hand, footAngle: 0);
  }

  Offset _solveIK2D(Offset start, Offset target, double l1, double l2) {
    final dist = (target - start).distance;
    final d = min(dist, l1 + l2 - 0.01);
    final cosAlpha = (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d);
    final alpha = acos(max(-1.0, min(1.0, cosAlpha)));
    final baseAngle = atan2(target.dy - start.dy, target.dx - start.dx);
    final kneeAngle = baseAngle + alpha;
    return Offset(cos(kneeAngle) * l1, sin(kneeAngle) * l1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BodyPart {
  final vm.Vector3 p1Orig;
  final vm.Vector3? p2Orig;
  final double r1, r2;
  final Color color;
  final bool isSphere;

  Offset p1 = Offset.zero;
  Offset p2 = Offset.zero;
  double z = 0;

  _BodyPart(
    this.p1Orig,
    this.p2Orig,
    this.r1,
    this.r2,
    this.color, {
    required this.isSphere,
  });

  void transform(vm.Matrix4 rot, double cx, double cy) {
    final t1 = rot.transformed3(p1Orig);
    p1 = Offset(cx + t1.x, t1.y + cy);
    z = t1.z;
    if (p2Orig != null) {
      final t2 = rot.transformed3(p2Orig!);
      p2 = Offset(cx + t2.x, t2.y + cy);
      z = (t1.z + t2.z) / 2;
    }
  }

  void draw(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;

    if (isSphere) {
      final rect = Rect.fromCircle(center: p1, radius: r1);
      paint.shader = RadialGradient(
        center: Alignment(-0.2, -0.25),
        radius: 0.8,
        colors: [
          Color.lerp(color, Colors.white, 0.2)!,
          color,
          Color.lerp(color, Colors.black, 0.3)!,
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect);
      canvas.drawCircle(p1, r1, paint);
    } else {
      final dir = p2 - p1;
      final angle = dir.direction;
      final rotAngle = angle + pi / 2;

      final o1a = p1 + Offset(cos(rotAngle) * r1, sin(rotAngle) * r1);
      final o1b = p1 + Offset(cos(rotAngle + pi) * r1, sin(rotAngle + pi) * r1);
      final o2a = p2 + Offset(cos(rotAngle) * r2, sin(rotAngle) * r2);
      final o2b = p2 + Offset(cos(rotAngle + pi) * r2, sin(rotAngle + pi) * r2);

      final path = Path();
      path.moveTo(o1a.dx, o1a.dy);
      path.lineTo(o2a.dx, o2a.dy);
      path.arcToPoint(o2b, radius: Radius.circular(r2), clockwise: true);
      path.lineTo(o1b.dx, o1b.dy);
      path.arcToPoint(o1a, radius: Radius.circular(r1), clockwise: true);
      path.close();

      canvas.save();
      canvas.translate(p1.dx, p1.dy);
      canvas.rotate(angle);

      final rect = Rect.fromLTWH(
        0,
        -max(r1, r2),
        dir.distance,
        max(r1, r2) * 2,
      );
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(color, Colors.black, 0.35)!,
          color,
          Color.lerp(color, Colors.white, 0.15)!,
          color,
          Color.lerp(color, Colors.black, 0.4)!,
        ],
        stops: [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(rect);

      canvas.rotate(-angle);
      canvas.translate(-p1.dx, -p1.dy);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }
}

class _LimbResult {
  final Offset knee, foot;
  final double footAngle;
  _LimbResult({
    required this.knee,
    required this.foot,
    required this.footAngle,
  });
}
