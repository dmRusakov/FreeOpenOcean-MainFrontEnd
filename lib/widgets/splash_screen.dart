import 'package:flutter/material.dart';

import '../core/theme/marine_palette.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Startup runs before the app theme is mounted, and a boat starting the
    // app at sea is far more likely to be in the dark than a phone on a desk.
    final chrome = MarinePalette.night.chrome;
    return Scaffold(
      backgroundColor: chrome.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/free-open-ocean.png', width: 280),
            const SizedBox(height: 18),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(chrome.primary),
                backgroundColor: chrome.outlineFaint,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading ...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w100,
                color: chrome.inkMuted,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'FreeOpenOcean.com',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w300,
                color: chrome.ink,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Modern Ocean Charting and Weather Applications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: chrome.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
