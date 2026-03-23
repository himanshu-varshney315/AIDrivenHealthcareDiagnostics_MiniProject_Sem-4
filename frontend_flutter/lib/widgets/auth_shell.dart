import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AuthShell extends StatelessWidget {
  final Widget child;
  final Widget footer;
  final bool showHero;
  final IconData? icon;
  final String? eyebrow;
  final String? title;
  final String? subtitle;
  final List<AuthStat> stats;

  const AuthShell({
    super.key,
    required this.child,
    required this.footer,
    this.showHero = true,
    this.icon,
    this.eyebrow,
    this.title,
    this.subtitle,
    this.stats = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          const _AuthBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = showHero && constraints.maxWidth >= 920;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          MediaQuery.of(context).padding.vertical -
                          40,
                    ),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 32),
                                  child: _AuthHero(
                                    icon: icon!,
                                    eyebrow: eyebrow!,
                                    subtitle: subtitle!,
                                    stats: stats,
                                    title: title!,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _AuthFormCard(
                                  footer: footer,
                                  child: child,
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showHero &&
                                      icon != null &&
                                      eyebrow != null &&
                                      title != null &&
                                      subtitle != null) ...[
                                    _AuthHero(
                                      icon: icon!,
                                      eyebrow: eyebrow!,
                                      subtitle: subtitle!,
                                      stats: stats,
                                      title: title!,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                  _AuthFormCard(footer: footer, child: child),
                                ],
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AuthStat {
  final String label;
  final String value;
  final Color tint;

  const AuthStat({
    required this.label,
    required this.value,
    required this.tint,
  });
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5FAFF), Color(0xFFF0F8F7), Color(0xFFFFF8F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -90,
          left: -20,
          child: _GlowOrb(
            size: 220,
            colors: [
              AppTheme.blue.withValues(alpha: 0.22),
              AppTheme.blue.withValues(alpha: 0),
            ],
          ),
        ),
        Positioned(
          top: 120,
          right: -60,
          child: _GlowOrb(
            size: 250,
            colors: [
              AppTheme.aqua.withValues(alpha: 0.20),
              AppTheme.aqua.withValues(alpha: 0),
            ],
          ),
        ),
        Positioned(
          bottom: -40,
          left: 40,
          child: _GlowOrb(
            size: 210,
            colors: [
              AppTheme.coral.withValues(alpha: 0.18),
              AppTheme.coral.withValues(alpha: 0),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _GlowOrb({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<AuthStat> stats;

  const _AuthHero({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: AppTheme.navy,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.navy.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          ),
          child: Text(
            eyebrow,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(height: 1.02),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats
              .map(
                (stat) => Container(
                  width: 132,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: stat.tint.withValues(alpha: 0.16),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: stat.tint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        stat.value,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stat.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  final Widget child;
  final Widget footer;

  const _AuthFormCard({required this.child, required this.footer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(children: [child, const SizedBox(height: 14), footer]),
    );
  }
}
