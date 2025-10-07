import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool showConfetti;

  const ConfettiOverlay({
    super.key,
    required this.child,
    this.showConfetti = false,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 8), // Increased from 5 to 8 seconds
    );
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showConfetti && !oldWidget.showConfetti) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
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
    return Stack(
      children: [
        widget.child,
        if (widget.showConfetti) ...[
          // Center top confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Downward
              emissionFrequency: 0.02, // Reduced from 0.05 for slower emission
              numberOfParticles: 15, // Reduced from 20
              maxBlastForce: 80, // Reduced from 100
              minBlastForce: 50, // Reduced from 80
              gravity: 0.15, // Reduced from 0.3 for slower fall
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
                Colors.red,
              ],
              createParticlePath: _drawStar,
            ),
          ),
          // Top left confetti
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 4, // Diagonal down-right
              blastDirectionality: BlastDirectionality.explosive, // Spread more
              emissionFrequency: 0.02,
              numberOfParticles: 12,
              maxBlastForce: 70,
              minBlastForce: 40,
              gravity: 0.15,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
          // Top right confetti
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3 * pi / 4, // Diagonal down-left
              blastDirectionality: BlastDirectionality.explosive, // Spread more
              emissionFrequency: 0.02,
              numberOfParticles: 12,
              maxBlastForce: 70,
              minBlastForce: 40,
              gravity: 0.15,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
          // Bottom left confetti (shoots upward)
          Align(
            alignment: Alignment.bottomLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 4, // Diagonal up-right
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.02,
              numberOfParticles: 10,
              maxBlastForce: 60,
              minBlastForce: 35,
              gravity: 0.15,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.yellow,
                Colors.cyan,
                Colors.lime,
              ],
            ),
          ),
          // Bottom right confetti (shoots upward)
          Align(
            alignment: Alignment.bottomRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -3 * pi / 4, // Diagonal up-left
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.02,
              numberOfParticles: 10,
              maxBlastForce: 60,
              minBlastForce: 35,
              gravity: 0.15,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.yellow,
                Colors.cyan,
                Colors.lime,
              ],
            ),
          ),
        ],
      ],
    );
  }
}
