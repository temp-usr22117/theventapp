import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  StreamSubscription<User?>? _authSubscription;
  Timer? _loginFallbackTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (!mounted) return;

        if (user != null) {
          _loginFallbackTimer?.cancel();
          Navigator.pushReplacementNamed(context, '/home');
          return;
        }

        _loginFallbackTimer ??= Timer(
          const Duration(seconds: 3),
          () {
            if (!mounted) return;
            if (FirebaseAuth.instance.currentUser == null) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _loginFallbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 150, height: 150),
              const SizedBox(height: 24),
              const Text(
                'TheVent',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Speak freely. Anonymously.',
                style: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}