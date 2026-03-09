import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _displayedText = "";
  final String _fullText = "CV Builder Pro";
  int _charIndex = 0;
  Timer? _typingTimer;

  final List<String> _quotes = [
    "Success starts with preparation!",
    "Build a CV that matches your dreams today.",
    "Have confidence in your abilities!",
    "A quality CV opens doors to job opportunities."
  ];
  late String _randomQuote;

  @override
  void initState() {
    super.initState();
    _randomQuote = _quotes[Random().nextInt(_quotes.length)];

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _typingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_charIndex < _fullText.length) {
        if (mounted) {
          setState(() {
            _displayedText += _fullText[_charIndex];
            _charIndex++;
          });
        }
      } else {
        timer.cancel();
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthWrapper(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC), // በጣም ቀላል ግራጫ (Off-white)
              Colors.white, // ንጹህ ነጭ
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(8, (index) => _buildAnimatedBubble(index)),
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _displayedText,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B), // ጥቁር ሰማያዊ ወይም Colors.black
                        letterSpacing: 2.5,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black12, // ጥላው በጣም ቀጭን እንዲሆን
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        _randomQuote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black
                              .withValues(alpha: 0.6), // ግልጽነት ያለው ጥቁር
                          fontSize: 17,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: 60,
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBubble(int index) {
    final random = Random();
    return Positioned(
      top: random.nextDouble() * 800,
      left: random.nextDouble() * 400,
      child: Opacity(
        opacity: 0.05,
        child: Container(
          width: (index + 1) * 35.0,
          height: (index + 1) * 35.0,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
