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
                  const Icon(
                    Icons.sailing_sharp,
                    size: 36,
                    color: Color(0xFF4FC3F7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'FreeOpenOcean',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Color(0xFFB0BEC5),
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
