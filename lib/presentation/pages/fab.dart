import 'package:flutter/material.dart';
import 'package:nutri_check/core/constants/app_colors.dart';
import 'package:nutri_check/core/constants/app_text_styles.dart';

class FloatingAICard extends StatefulWidget {
  final VoidCallback onPressed;

  const FloatingAICard({super.key, required this.onPressed});

  @override
  State<FloatingAICard> createState() => _FloatingAICardState();
}

class _FloatingAICardState extends State<FloatingAICard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _glowController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_hoverAnimation, _glowAnimation]),
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.all(20),
          child: GestureDetector(
            onTapDown: (_) => _hoverController.forward(),
            onTapUp: (_) {
              _hoverController.reverse();
              widget.onPressed();
            },
            onTapCancel: () => _hoverController.reverse(),
            child: Transform.translate(
              offset: Offset(0, -_hoverAnimation.value),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(
                        _glowAnimation.value,
                      ),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Meal Analysis',
                            style: AppTextStyles.headingSmall(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Snap a photo and get instant nutrition insights powered by Gemini AI!',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: Colors.white.withOpacity(0.9),
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.flash_on,
                                color: Colors.yellow.shade300,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Instant • Accurate • Smart',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
