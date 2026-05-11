import 'package:flutter/material.dart';

/// On-brand loading placeholder for search result product cards.
///
/// Mirrors the layout of the real product card so the transition into
/// loaded results is visually stable. Uses a gentle opacity pulse on
/// theme-tinted shapes instead of a shimmer sweep — the whole card
/// "breathes" between 0.55 and 1.0 opacity in unison.
class SearchSkeleton extends StatefulWidget {
  final int itemCount;

  const SearchSkeleton({super.key, this.itemCount = 6});

  @override
  State<SearchSkeleton> createState() => _SearchSkeletonState();
}

class _SearchSkeletonState extends State<SearchSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.itemCount,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => FadeTransition(
              opacity: _animation,
              child: _SkeletonCard(scheme: scheme),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final ColorScheme scheme;

  const _SkeletonCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          // Text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title bar
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.7,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Category pill bar
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.25,
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Two nutrient pill bars
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Trailing dot
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
