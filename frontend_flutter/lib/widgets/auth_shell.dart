import 'package:flutter/material.dart';

import '../config/app_identity.dart';
import '../theme/app_theme.dart';
import 'brand_mark.dart';

class AuthShell extends StatelessWidget {
  final Widget child;
  final Widget footer;
  final bool showHero;
  final String? eyebrow;
  final String? title;
  final String? subtitle;
  final List<AuthStat> stats;

  const AuthShell({
    super.key,
    required this.child,
    required this.footer,
    this.showHero = true,
    this.eyebrow,
    this.title,
    this.subtitle,
    this.stats = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = showHero && constraints.maxWidth > 860;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight -
                      MediaQuery.of(context).padding.vertical -
                      36,
                ),
                child: wide
                    ? Row(
                        children: [
                          Expanded(
                            child: _HeroPanel(
                              eyebrow: eyebrow ?? AppIdentity.appName,
                              title: title ?? 'Your care dashboard, simplified',
                              subtitle:
                                  subtitle ?? AppIdentity.appShortDescription,
                              stats: stats,
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: _FormPanel(footer: footer, child: child),
                          ),
                        ],
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showHero)
                                _HeroPanel(
                                  compact: true,
                                  eyebrow: eyebrow ?? AppIdentity.appName,
                                  title:
                                      title ??
                                      'Your care dashboard, simplified',
                                  subtitle:
                                      subtitle ??
                                      AppIdentity.appShortDescription,
                                  stats: stats,
                                ),
                              if (showHero) const SizedBox(height: 16),
                              _FormPanel(footer: footer, child: child),
                            ],
                          ),
                        ),
                      ),
              ),
            );
          },
        ),
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

class _HeroPanel extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<AuthStat> stats;
  final bool compact;

  const _HeroPanel({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.stats,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 22 : 34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.heroGradient,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AyuvaBrandMark(
                size: compact ? 50 : 58,
                tone: AyuvaMarkTone.light,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  eyebrow.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 18 : 34),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: compact ? 30 : 38,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: stats
                  .map(
                    (stat) => Container(
                      width: compact ? 112 : 128,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stat.label,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  final Widget child;
  final Widget footer;

  const _FormPanel({required this.child, required this.footer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1010222D),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(children: [child, const SizedBox(height: 14), footer]),
    );
  }
}

class AuthStatusBanner extends StatelessWidget {
  final String message;

  const AuthStatusBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.scrub,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.clinicalGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.clinicalGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
