import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/app_colors.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController logoController;
  late AnimationController loadingController;

  late Animation<double> logoScale;
  late Animation<double> logoFade;

  @override
  void initState() {
    super.initState();

    logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: logoController, curve: Curves.elasticOut),
    );

    logoFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: logoController, curve: Curves.easeIn));

    logoController.forward();
    loadingController.forward();

    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate(),
      );
    });
  }

  @override
  void dispose() {
    logoController.dispose();
    loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: logoFade,
              child: ScaleTransition(
                scale: logoScale,
                child: Column(
                  children: [
                    Image.asset('assets/images/LOGO.png', width: 220),
                    Container(width: 230, height: 4, color: AppColors.blue),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),

            Container(
              width: 230,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedBuilder(
                animation: loadingController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Container(
                        width: 230 * loadingController.value,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'LOADING...',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
