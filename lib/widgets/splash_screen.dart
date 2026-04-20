import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2332),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Spinning ring
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FC3F7)),
                      backgroundColor: Color(0x1AFFFFFF),
                    ),
                  ),
                  // Sailing icon
                  const Text(
                    '⛵',
                    style: TextStyle(fontSize: 45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading ...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w100,
                color: Color(0xFFB0BEC5),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'FreeOpenOcean.com',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w300,
                color: Color(0xFFB0BEC5),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Modern Ocean Charting and Weather Applications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: Color(0xFFB0BEC5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}