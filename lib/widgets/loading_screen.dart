import 'package:flutter/material.dart';

/// Full-screen animated loading overlay shown while the website loads.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
        ),
      ),
      child: Stack(
        children: [
          const _FloatingBubble(
            left: 40,
            top: 100,
            size: 16,
            duration: Duration(seconds: 4),
            delay: Duration(milliseconds: 600),
          ),
          const _FloatingBubble(
            right: 60,
            top: 160,
            size: 24,
            duration: Duration(seconds: 5),
            delay: Duration(milliseconds: 1200),
          ),
          const _FloatingBubble(
            left: 80,
            bottom: 200,
            size: 20,
            duration: Duration(seconds: 6),
            delay: Duration(milliseconds: 300),
          ),
          const _FloatingBubble(
            right: 100,
            bottom: 300,
            size: 12,
            duration: Duration(seconds: 4),
            delay: Duration(milliseconds: 900),
          ),
          const _FloatingBubble(
            left: 160,
            top: 60,
            size: 14,
            duration: Duration(seconds: 5),
            delay: Duration(milliseconds: 1500),
          ),
          const _FloatingBubble(
            right: 200,
            top: 400,
            size: 18,
            duration: Duration(seconds: 7),
            delay: Duration(milliseconds: 400),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const _AnimatedWord(word: 'My Study Archive'),

                  const SizedBox(height: 8),
                  Text(
                  'Loading the resources...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  const _DotLoader(),
                ],
              ),
            ),
          ),

          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: _WaveLoader(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dot loader that pulses in a circle pattern.
class _DotLoader extends StatefulWidget {
  const _DotLoader();

  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Opacity(
                  opacity: ((_controller.value - i / 3) % 1).abs() < 0.5
                      ? 1.0
                      : 0.3,
                  child: Transform.scale(
                    scale:
                        0.6 + ((_controller.value - i / 3) % 1).abs() * 0.8,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Floating white bubble in the background.
class _FloatingBubble extends StatefulWidget {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double size;
  final Duration duration;
  final Duration delay;

  const _FloatingBubble({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.size,
    required this.duration,
    required this.delay,
  });

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _offset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -30.0), weight: 1.0),
      TweenSequenceItem(tween: Tween(begin: -30.0, end: 0.0), weight: 1.0),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1.0,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Positioned(
          left: widget.left,
          right: widget.right,
          top: widget.top,
          bottom: widget.bottom,
          child: Transform.translate(
            offset: Offset(0, _offset.value),
            child: Opacity(
              opacity: _opacity.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Animates each character of a word, dropping in with a bounce.
class _AnimatedWord extends StatefulWidget {
  final String word;

  const _AnimatedWord({required this.word});

  @override
  State<_AnimatedWord> createState() => _AnimatedWordState();
}

class _AnimatedWordState extends State<_AnimatedWord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _charAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 130 * widget.word.length),
    )..forward();

    _charAnimations = List.generate(
      widget.word.length,
      (i) => CurvedAnimation(
        parent: _controller,
        curve: Interval(
          i / widget.word.length,
          (i + 1) / widget.word.length,
          curve: Curves.easeOutBack,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < widget.word.length; i++)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _charAnimations[i].value;
              return Transform.translate(
                offset: Offset(0, -20 * (1 - t)),
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Text(
                    widget.word[i],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Bottom wave loader (pulsing dots).
class _WaveLoader extends StatefulWidget {
  const _WaveLoader();

  @override
  State<_WaveLoader> createState() => _WaveLoaderState();
}

class _WaveLoaderState extends State<_WaveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 6; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Transform.scale(
                  scale: 0.4 + ((_controller.value - i / 6) % 1).abs() * 0.8,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}