import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

class EasterEggScreen extends StatefulWidget {
  const EasterEggScreen({super.key});

  @override
  State<EasterEggScreen> createState() => _EasterEggScreenState();
}

class _EasterEggScreenState extends State<EasterEggScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _emojiController;
  late AnimationController _pulseController;
  late ConfettiController _confettiController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  final Random _random = Random();
  List<FloatingEmoji> _floatingEmojis = [];

  @override
  void initState() {
    super.initState();

    // Text fade and scale animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );

    // Pulse animation for heart
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Emoji floating animation
    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 12), // Increased from 10 to 12 seconds
    );

    // Start animations
    _textController.forward();
    _confettiController.play();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    if (_floatingEmojis.isEmpty && size.width > 0 && size.height > 0) {
      _floatingEmojis = List.generate(
        15,
        (index) => _createFloatingEmoji(size),
      );
    }
  }

  FloatingEmoji _createFloatingEmoji(Size size) {
    final emojis = ['😘', '💋', '❤️', '💕', '💖', '💗', '💓', '💞', '💝'];
    return FloatingEmoji(
      emoji: emojis[_random.nextInt(emojis.length)],
      x: _random.nextDouble() * size.width,
      y: size.height + _random.nextDouble() * 100,
      speed: 0.5 + _random.nextDouble() * 1.5,
      size: 20.0 + _random.nextDouble() * 20,
      delay: _random.nextDouble() * 5,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _emojiController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Path _drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * cos(step),
        halfWidth + externalRadius * sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.shade100,
                  Colors.purple.shade100,
                  Colors.red.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Animated floating emojis
          AnimatedBuilder(
            animation: _emojiController,
            builder: (context, child) {
              return Stack(
                children:
                    _floatingEmojis.map((emoji) {
                      final progress =
                          (_emojiController.value + emoji.delay) % 1.0;
                      final yPos =
                          size.height - (progress * (size.height + 100));
                      final xOffset = sin(progress * 4 * pi) * 30;

                      return Positioned(
                        left: emoji.x + xOffset,
                        top: yPos,
                        child: Opacity(
                          opacity:
                              progress < 0.1
                                  ? progress * 10
                                  : (progress > 0.9 ? (1 - progress) * 10 : 1),
                          child: Text(
                            emoji.emoji,
                            style: TextStyle(fontSize: emoji.size),
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
          ),

          // Confetti - spread across entire screen
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.02, // Reduced for slower emission
              numberOfParticles: 20, // Reduced from 30
              maxBlastForce: 80, // Reduced from 100
              minBlastForce: 50, // Reduced from 80
              gravity: 0.08, // Reduced from 0.1 for slower fall
              shouldLoop: true,
              colors: const [
                Colors.pink,
                Colors.red,
                Colors.purple,
                Colors.orange,
                Colors.deepPurple,
              ],
              createParticlePath: _drawStar,
            ),
          ),
          // Left side confetti
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 0, // Right
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.02,
              numberOfParticles: 15,
              maxBlastForce: 70,
              minBlastForce: 40,
              gravity: 0.08,
              shouldLoop: true,
              colors: const [
                Colors.pink,
                Colors.red,
                Colors.purple,
                Colors.orange,
              ],
            ),
          ),
          // Right side confetti
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi, // Left
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.02,
              numberOfParticles: 15,
              maxBlastForce: 70,
              minBlastForce: 40,
              gravity: 0.08,
              shouldLoop: true,
              colors: const [
                Colors.pink,
                Colors.red,
                Colors.purple,
                Colors.orange,
              ],
            ),
          ),

          // Center content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated "I love you" text
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'I Love You!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              foreground:
                                  Paint()
                                    ..shader = LinearGradient(
                                      colors: [
                                        Colors.pink.shade400,
                                        Colors.red.shade400,
                                        Colors.purple.shade400,
                                      ],
                                    ).createShader(
                                      const Rect.fromLTWH(0, 0, 200, 70),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '- Kailash',
                            style: TextStyle(
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Pulsing heart
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: const Text('❤️', style: TextStyle(fontSize: 100)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingEmoji {
  final String emoji;
  final double x;
  final double y;
  final double speed;
  final double size;
  final double delay;

  FloatingEmoji({
    required this.emoji,
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.delay,
  });
}
