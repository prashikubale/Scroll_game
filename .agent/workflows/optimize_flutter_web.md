---
description: Optimize Flutter Web Application Performance to Crazy Level
---

## Overview
This workflow outlines a systematic approach to dramatically improve the performance of the **Scroll Game** Flutter web application when running on Chrome. It focuses on reducing frame drops, minimizing jank, and delivering a smooth, responsive experience.

## Steps
1. **Run in Release Mode**
   ```bash
   flutter run -d chrome --release
   ```
   *Release mode disables debug checks and enables tree‑shaking, drastically improving FPS.*

2. **Enable Flutter Performance Overlay**
   Add the overlay to `MyApp` to visualise raster and UI thread usage:
   ```dart
   return MaterialApp(
     showPerformanceOverlay: true,
     // ... existing properties
   );
   ```
   Observe the overlay in Chrome and note any spikes above 16 ms per frame.

3. **Profile with DevTools**
   - Run `flutter pub global activate devtools && flutter pub global run devtools`.
   - Open the **Timeline** tab while interacting with the game.
   - Identify the most expensive frames (usually > 30 ms).

4. **Add `RepaintBoundary`**
   Wrap heavy widgets (e.g., `CatchGameWidget`, `WhackMoleGame`, particle systems) with `RepaintBoundary` to isolate repaints.
   ```dart
   RepaintBoundary(
     child: CatchGameWidget(controller: controller),
   );
   ```

5. **Optimize Object Updates**
   - Reduce the number of objects updated each tick. For example, limit falling objects to a maximum of 30.
   - Use `List.removeWhere` sparingly; replace with a manual loop that reuses a pre‑allocated list to avoid allocations.
   - Cache `MediaQuery.of(context).size` in a local variable inside the build method to avoid repeated look‑ups.

6. **Custom Painter Optimisation**
   If any game uses `CustomPainter`:
   - Override `shouldRepaint` to return `true` **only** when the underlying data changes.
   - Cache `Paint` objects as `static final` to avoid recreation each frame.

7. **Image Asset Compression**
   - Run `flutter pub run flutter_image_compress` on all PNG/JPG assets.
   - Ensure assets are no larger than 200 KB.
   - Use `precacheImage` in `initState` for assets used frequently.

8. **Reduce Widget Rebuilds**
   - Convert stateless widgets that depend only on immutable data to `const` constructors.
   - Use `ConsumerWidget` (Riverpod) with `select` to listen only to the needed slice of state.
   - Avoid calling `setState` inside tight loops; batch state changes and call `notifyListeners` once per frame.

9. **Limit Animations to 60 fps**
   - Ensure any `Timer.periodic` that drives animation uses a 16 ms interval (`Duration(milliseconds: 16)`).
   - Prefer `AnimationController` with `vsync` instead of manual timers.

10. **Web‑Specific Tweaks**
    - Add `<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">` to `web/index.html` to prevent unnecessary scaling.
    - Set `canvasKit` rendering for higher performance:
      ```bash
      flutter build web --web-renderer canvaskit
      ```
    - Deploy the generated `build/web` folder to a static server (e.g., Vercel) and test the production bundle.

11. **Continuous Monitoring**
    - After each change, run the app in release mode and capture FPS with Chrome DevTools (`Performance` tab).
    - Aim for **≥ 55 fps** on typical devices; if you see dips, revisit steps 4‑9.

## Checklist
- [ ] Run in release mode
- [ ] Add `showPerformanceOverlay`
- [ ] Profile with DevTools
- [ ] Wrap heavy widgets in `RepaintBoundary`
- [ ] Limit object count & reuse lists
- [ ] Optimize `CustomPainter`
- [ ] Compress assets & precache
- [ ] Convert to `const` where possible
- [ ] Use Riverpod `select`
- [ ] Use `AnimationController` instead of raw timers
- [ ] Enable CanvasKit rendering
- [ ] Verify FPS ≥ 55 on Chrome

---

**Note:** This workflow is intentionally exhaustive to achieve “crazy‑level” performance. Apply each step incrementally and verify improvements before proceeding to the next.
