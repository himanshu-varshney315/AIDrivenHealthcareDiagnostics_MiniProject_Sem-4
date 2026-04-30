import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_identity.dart';
import '../services/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

const List<_SplashSlide> _slides = [
  _SplashSlide(
    title: 'Upload reports',
    subtitle: 'Keep PDFs and lab results organized in one calm health record.',
    highlight: 'Fast setup',
  ),
  _SplashSlide(
    title: 'Track patterns',
    subtitle: 'Review AI summaries and spot changes without extra noise.',
    highlight: 'Smart analysis',
  ),
  _SplashSlide(
    title: 'Find care faster',
    subtitle:
        'Move from reports to nearby clinics and follow-up with less effort.',
    highlight: 'Clinic support',
  ),
];

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _sequenceDuration = Duration(milliseconds: 1800);
  static const Duration _floatDuration = Duration(milliseconds: 2400);
  static const Duration _slideDuration = Duration(milliseconds: 2400);
  static const Duration _transitionDuration = Duration(milliseconds: 700);

  late final AnimationController _sequenceController;
  late final AnimationController _floatController;
  late final PageController _pageController;
  late final Animation<double> _brandScale;
  late final Animation<double> _sceneOpacity;
  late final Animation<Offset> _sceneSlide;
  Timer? _slideTimer;
  int _currentSlide = 0;
  bool _hasActiveSession = false;

  @override
  void initState() {
    super.initState();
    _sequenceController = AnimationController(
      vsync: this,
      duration: _sequenceDuration,
    )..forward();

    _floatController = AnimationController(
      vsync: this,
      duration: _floatDuration,
    )..repeat(reverse: true);
    _pageController = PageController();

    _brandScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOutBack),
      ),
    );
    _sceneOpacity = CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(0.22, 0.48, curve: Curves.easeOutCubic),
    );
    _sceneSlide = Tween<Offset>(begin: const Offset(0, 0.045), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _sequenceController,
            curve: const Interval(0.24, 0.52, curve: Curves.easeOutCubic),
          ),
        );

    _restoreSessionState();
    _scheduleNextSlide();
  }

  Future<void> _restoreSessionState() async {
    final session = await AuthController.loadSession();
    if (!mounted) return;
    setState(
      () => _hasActiveSession = AuthController.hasActiveSession(session),
    );
  }

  void _scheduleNextSlide() {
    _slideTimer?.cancel();
    _slideTimer = Timer(_slideDuration, _advanceSlide);
  }

  Future<void> _advanceSlide() async {
    if (!mounted) return;

    if (_currentSlide >= _slides.length - 1) {
      _navigateNext();
      return;
    }

    final int nextSlide = _currentSlide + 1;
    setState(() => _currentSlide = nextSlide);
    await _pageController.animateToPage(
      nextSlide,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
    _scheduleNextSlide();
  }

  void _navigateNext() {
    if (!mounted) return;
    _slideTimer?.cancel();
    final Widget target = _hasActiveSession
        ? const DashboardScreen()
        : const LoginScreen();
    final RouteSettings settings = RouteSettings(
      name: _hasActiveSession ? '/dashboard' : '/login',
    );
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: settings,
        transitionDuration: _transitionDuration,
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _sequenceController.dispose();
    _floatController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([_sequenceController, _floatController]),
        builder: (context, child) {
          final double introOpacity =
              (1 - ((_sequenceController.value - 0.16) / 0.14))
                  .clamp(0.0, 1.0)
                  .toDouble();

          return Stack(
            children: [
              const _Backdrop(),
              if (introOpacity > 0)
                Positioned.fill(
                  child: Opacity(
                    opacity: introOpacity,
                    child: Transform.scale(
                      scale: _brandScale.value,
                      child: const _BrandIntro(),
                    ),
                  ),
                ),
              Positioned.fill(
                child: FadeTransition(
                  opacity: _sceneOpacity,
                  child: SlideTransition(
                    position: _sceneSlide,
                    child: _OnboardingScene(
                      drift: _floatController.value,
                      currentSlide: _currentSlide,
                      pageController: _pageController,
                      hasActiveSession: _hasActiveSession,
                      onSkip: _navigateNext,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFFFCFCFF)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.scrub.withValues(alpha: 0.65),
                  AppTheme.background,
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandIntro extends StatelessWidget {
  const _BrandIntro();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AyuvaBrandMark(size: 104),
              const SizedBox(height: 24),
              Text(
                AppIdentity.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 50,
                  letterSpacing: 0,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppIdentity.appTagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingScene extends StatelessWidget {
  final double drift;
  final int currentSlide;
  final PageController pageController;
  final bool hasActiveSession;
  final VoidCallback onSkip;

  const _OnboardingScene({
    required this.drift,
    required this.currentSlide,
    required this.pageController,
    required this.hasActiveSession,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 640;
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;
          final bool shortScreen = height < 760;
          final double illustrationHeight = shortScreen
              ? height * 0.27
              : height * 0.35;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 22 : 34,
              compact ? 18 : 24,
              compact ? 22 : 34,
              shortScreen ? 10 : 16,
            ),
            child: Column(
              children: [
                _TopBar(
                  currentSlide: currentSlide,
                  hasActiveSession: hasActiveSession,
                  onTap: onSkip,
                ),
                SizedBox(height: shortScreen ? 10 : (compact ? 18 : 22)),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: illustrationHeight
                            .clamp(168.0, 300.0)
                            .toDouble(),
                        width: width,
                        child: _IllustrationStage(drift: drift),
                      ),
                      SizedBox(height: shortScreen ? 6 : 14),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: _LowerPanel(
                              compact: compact,
                              shortScreen: shortScreen,
                              currentSlide: currentSlide,
                              pageController: pageController,
                            ),
                          ),
                        ),
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

class _TopBar extends StatelessWidget {
  final int currentSlide;
  final bool hasActiveSession;
  final VoidCallback onTap;

  const _TopBar({
    required this.currentSlide,
    required this.hasActiveSession,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (index) {
            final bool selected = index == currentSlide;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: selected ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.blue
                    : AppTheme.blue.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const Spacer(),
        Material(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                hasActiveSession ? 'Resume' : 'Login',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IllustrationStage extends StatelessWidget {
  final double drift;

  const _IllustrationStage({required this.drift});

  @override
  Widget build(BuildContext context) {
    final double sine = math.sin(drift * math.pi * 2);
    final double cosine = math.cos(drift * math.pi * 2);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 54 + (cosine * 10),
          top: 10 + (sine * 8),
          child: _BlobCharacter(
            width: 106,
            height: 96,
            color: const Color(0xFF3F73F4),
            shape: BlobShape.flower,
            eyeOffset: const Offset(0, -2),
            rotation: -0.1,
          ),
        ),
        Positioned(
          right: 58 - (cosine * 8),
          top: 72 - (sine * 7),
          child: _BlobCharacter(
            width: 82,
            height: 74,
            color: AppTheme.aqua,
            shape: BlobShape.chatFlower,
            eyeOffset: const Offset(-1, 0),
            rotation: 0.08,
          ),
        ),
        Positioned(
          left: 34 - (cosine * 7),
          bottom: 36 + (sine * 7),
          child: _BlobCharacter(
            width: 86,
            height: 92,
            color: AppTheme.clinicalGreen,
            shape: BlobShape.droplet,
            eyeOffset: const Offset(0, -2),
            rotation: -0.1,
          ),
        ),
        Positioned(
          left: 148 + (cosine * 6),
          top: 54 + (sine * 4),
          child: _MiniBlob(color: AppTheme.blue),
        ),
        Positioned(
          left: 30 + (cosine * 6),
          top: 128 - (sine * 4),
          child: _MiniBlob(color: AppTheme.aqua, size: 22),
        ),
        Positioned(
          left: 112 - (cosine * 4),
          bottom: 82 + (sine * 5),
          child: _MiniBlob(color: AppTheme.clinicalGreen, size: 20),
        ),
        Positioned(
          right: 114,
          bottom: 52 - (sine * 8),
          child: Container(
            width: 74,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.scrub,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.smartphone_rounded,
                color: AppTheme.clinicalGreen,
                size: 22,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 18,
          child: Center(
            child: Container(
              width: 110,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.backgroundRaised,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LowerPanel extends StatelessWidget {
  final bool compact;
  final bool shortScreen;
  final int currentSlide;
  final PageController pageController;

  const _LowerPanel({
    required this.compact,
    required this.shortScreen,
    required this.currentSlide,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: shortScreen ? 34 : 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _CloudBump(height: shortScreen ? 22 : 28)),
              Expanded(child: _CloudBump(height: shortScreen ? 30 : 38)),
              Expanded(child: _CloudBump(height: shortScreen ? 20 : 26)),
              Expanded(child: _CloudBump(height: shortScreen ? 32 : 40)),
              Expanded(child: _CloudBump(height: shortScreen ? 24 : 30)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              compact ? 22 : 34,
              shortScreen ? 12 : (compact ? 18 : 28),
              compact ? 22 : 34,
              shortScreen ? 10 : (compact ? 16 : 22),
            ),
            decoration: const BoxDecoration(
              color: AppTheme.softSurface,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return _SlideContent(
                        slide: slide,
                        compact: compact,
                        shortScreen: shortScreen,
                      );
                    },
                  ),
                ),
                SizedBox(height: shortScreen ? 6 : 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    final bool selected = index == currentSlide;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: selected ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.navy
                            : AppTheme.navy.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                SizedBox(height: shortScreen ? 6 : 10),
                const SizedBox(
                  width: 84,
                  child: Divider(color: Color(0x33000000), thickness: 3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SlideContent extends StatelessWidget {
  final _SplashSlide slide;
  final bool compact;
  final bool shortScreen;

  const _SlideContent({
    required this.slide,
    required this.compact,
    required this.shortScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          slide.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: shortScreen ? (compact ? 24 : 28) : (compact ? 28 : 36),
            height: 1.0,
            color: AppTheme.navy,
          ),
        ),
        SizedBox(height: shortScreen ? 8 : 12),
        Text(
          slide.subtitle,
          textAlign: TextAlign.center,
          maxLines: shortScreen ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textMuted,
            fontSize: shortScreen ? 13 : (compact ? 14.5 : 16),
            height: 1.25,
          ),
        ),
        SizedBox(height: shortScreen ? 12 : 16),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: shortScreen ? 14 : 16,
            vertical: shortScreen ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            slide.highlight,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.navy,
              fontWeight: FontWeight.w700,
              fontSize: shortScreen ? 12.5 : 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _CloudBump extends StatelessWidget {
  final double height;

  const _CloudBump({required this.height});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppTheme.softSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}

class _SplashSlide {
  final String title;
  final String subtitle;
  final String highlight;

  const _SplashSlide({
    required this.title,
    required this.subtitle,
    required this.highlight,
  });
}

enum BlobShape { flower, chatFlower, droplet }

class _BlobCharacter extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final BlobShape shape;
  final Offset eyeOffset;
  final double rotation;

  const _BlobCharacter({
    required this.width,
    required this.height,
    required this.color,
    required this.shape,
    required this.eyeOffset,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: _BlobPainter(color: color, shape: shape),
            ),
            Transform.translate(
              offset: eyeOffset,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [_BlobEye(), SizedBox(width: 8), _BlobEye()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlobEye extends StatelessWidget {
  const _BlobEye();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.15,
      child: Container(
        width: 10,
        height: 15,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _MiniBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _MiniBlob({required this.color, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.45),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Color color;
  final BlobShape shape;

  const _BlobPainter({required this.color, required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = switch (shape) {
      BlobShape.flower => _flowerPath(size),
      BlobShape.chatFlower => _chatFlowerPath(size),
      BlobShape.droplet => _dropletPath(size),
    };
    canvas.drawPath(path, paint);
  }

  Path _flowerPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.16, h * 0.42);
    path.cubicTo(w * 0.04, h * 0.30, w * 0.08, h * 0.12, w * 0.26, h * 0.13);
    path.cubicTo(w * 0.28, h * 0.02, w * 0.47, h * 0.00, w * 0.55, h * 0.10);
    path.cubicTo(w * 0.70, h * 0.01, w * 0.88, h * 0.11, w * 0.84, h * 0.28);
    path.cubicTo(w * 0.97, h * 0.35, w * 0.99, h * 0.55, w * 0.84, h * 0.63);
    path.cubicTo(w * 0.90, h * 0.81, w * 0.72, h * 0.95, w * 0.56, h * 0.88);
    path.cubicTo(w * 0.45, h * 1.00, w * 0.24, h * 0.95, w * 0.23, h * 0.80);
    path.cubicTo(w * 0.07, h * 0.77, w * 0.00, h * 0.59, w * 0.16, h * 0.42);
    path.close();
    return path;
  }

  Path _chatFlowerPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = _flowerPath(size);
    path.moveTo(w * 0.52, h * 0.90);
    path.cubicTo(w * 0.47, h * 1.00, w * 0.41, h * 1.02, w * 0.36, h * 0.93);
    path.close();
    return path;
  }

  Path _dropletPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.50, h * 0.04);
    path.cubicTo(w * 0.77, h * 0.08, w * 0.92, h * 0.32, w * 0.84, h * 0.55);
    path.cubicTo(w * 0.80, h * 0.73, w * 0.66, h * 0.84, w * 0.55, h * 0.88);
    path.cubicTo(w * 0.46, h * 0.99, w * 0.32, h * 1.00, w * 0.26, h * 0.87);
    path.cubicTo(w * 0.12, h * 0.77, w * 0.05, h * 0.59, w * 0.09, h * 0.43);
    path.cubicTo(w * 0.14, h * 0.22, w * 0.28, h * 0.07, w * 0.50, h * 0.04);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shape != shape;
  }
}
