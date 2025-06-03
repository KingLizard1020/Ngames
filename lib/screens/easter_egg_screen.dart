import 'dart:math';
import 'package:flutter/material.dart';

class EasterEggScreen extends StatefulWidget {
  const EasterEggScreen({super.key});

  @override
  State<EasterEggScreen> createState() => _EasterEggScreenState();
}

class _EasterEggScreenState extends State<EasterEggScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Generate initial particles
    for (int i = 0; i < 50; i++) {
      _particles.add(
        _createParticle(
          Size(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height,
          ),
        ),
      );
    }
  }

  Particle _createParticle(Size canvasSize) {
    return Particle(
      x: _random.nextDouble() * canvasSize.width,
      y:
          _random.nextDouble() * canvasSize.height * 0.2 -
          canvasSize.height * 0.1, // Start near top
      size: _random.nextDouble() * 15 + 10, // Hearts and confetti size
      color: Color.fromRGBO(
        _random.nextInt(256),
        _random.nextInt(256),
        _random.nextInt(256),
        1,
      ),
      isHeart: _random.nextBool(),
      ySpeed: _random.nextDouble() * 2 + 1,
      xSpeed: _random.nextDouble() * 2 - 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-initialize particles if screen size is available and changes (e.g. orientation)
    // This is a simplified way; a more robust way would be to handle layout changes.
    final size = MediaQuery.of(context).size;
    if (size.width > 0 && size.height > 0) {
      _particles = List.generate(50, (_) => _createParticle(size));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Update particle positions
          final size = MediaQuery.of(context).size;
          for (var particle in _particles) {
            particle.y += particle.ySpeed;
            particle.x += particle.xSpeed;
            if (particle.y > size.height) {
              particle.y =
                  _random.nextDouble() * size.height * 0.1 - 50; // Reset to top
              particle.x = _random.nextDouble() * size.width;
            }
          }
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                  theme.colorScheme.tertiaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Particles CustomPaint
                CustomPaint(
                  size: Size.infinite,
                  painter: ConfettiPainter(_particles),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'I love you - Kailash',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Icon(
                        Icons.favorite,
                        color: Colors.red.shade400,
                        size: 80,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class Particle {
  double x, y, size, ySpeed, xSpeed;
  Color color;
  bool isHeart;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.isHeart,
    required this.ySpeed,
    required this.xSpeed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<Particle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var particle in particles) {
      paint.color = particle.color;
      if (particle.isHeart) {
        // Draw a simple heart shape
        final path = Path();
        path.moveTo(particle.x, particle.y - particle.size / 2);
        path.cubicTo(
          particle.x - particle.size * 1.2,
          particle.y - particle.size * 1.2,
          particle.x - particle.size * 0.7,
          particle.y + particle.size * 0.5,
          particle.x,
          particle.y + particle.size * 0.8,
        );
        path.cubicTo(
          particle.x + particle.size * 0.7,
          particle.y + particle.size * 0.5,
          particle.x + particle.size * 1.2,
          particle.y - particle.size * 1.2,
          particle.x,
          particle.y - particle.size / 2,
        );
        canvas.drawPath(path, paint);
      } else {
        // Draw a simple confetti rectangle
        canvas.drawRect(
          Rect.fromLTWH(
            particle.x - particle.size / 2,
            particle.y - particle.size / 2,
            particle.size * 0.7,
            particle.size * 1.2,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true; // Repaint every frame for animation
}
