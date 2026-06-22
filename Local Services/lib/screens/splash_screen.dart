import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.onGetStarted, super.key});

  final VoidCallback onGetStarted;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _wordFade;
  late final Animation<Offset> _btnSlide;
  late final Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOut),
      ),
    );
    _wordFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.32, 0.62, curve: Curves.easeOut),
      ),
    );
    _btnSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.58, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.58, 0.88, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2F6BFF), Color(0xFF0D34A8)],
          ),
        ),
        child: Stack(
          children: [
            // decorative circles
            const Positioned(
              top: -60,
              right: -60,
              child: _Circle(size: 260, opacity: 0.06),
            ),
            const Positioned(
              bottom: 120,
              left: -80,
              child: _Circle(size: 200, opacity: 0.05),
            ),
            const Positioned(
              bottom: -40,
              right: -20,
              child: _Circle(size: 180, opacity: 0.07),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 3),

                    // logo
                    Center(
                      child: AnimatedBuilder(
                        animation: _ctrl,
                        builder: (context, child) => FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: child,
                          ),
                        ),
                        child: Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            color: const Color(0x22FFFFFF),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0x44FFFFFF),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x28000000),
                                blurRadius: 32,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_repair_service,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // app name + tagline
                    FadeTransition(
                      opacity: _wordFade,
                      child: const Column(
                        children: [
                          Text(
                            'Local Services',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Trusted help,\nright in your neighbourhood',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 4),

                    // Get Started button
                    FadeTransition(
                      opacity: _btnFade,
                      child: SlideTransition(
                        position: _btnSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 58,
                              child: ElevatedButton(
                                onPressed: widget.onGetStarted,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1240C7),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Electricians · Plumbers · Cleaners · and more',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0x88FFFFFF),
                                fontSize: 12.5,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final alpha = (opacity * 255).round();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.fromARGB(alpha, 255, 255, 255),
        shape: BoxShape.circle,
      ),
    );
  }
}
