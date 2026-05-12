import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutri_check/core/config/env_config.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';

import '../../widgets/nutrition/add_manual_meal_sheet.dart';

class AIMealAnalysisPage extends StatefulWidget {
  const AIMealAnalysisPage({super.key});

  @override
  State<AIMealAnalysisPage> createState() => _AIMealAnalysisPageState();
}

class _AIMealAnalysisPageState extends State<AIMealAnalysisPage>
    with TickerProviderStateMixin {
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  final ImagePicker _picker = ImagePicker();

  // Portion correction state.
  double _estimatedGrams = 100;
  double _currentGrams = 100;
  String _confidence = 'unknown';

  // OpenFoodFacts cross-check state.
  Map<String, double>? _offPer100;
  String? _offMatchName;
  bool _checkingOff = false;
  bool _useOff = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  static String get _apiKey => EnvConfig.groqApiKey;
  static const String _visionModel =
      'meta-llama/llama-4-scout-17b-16e-instruct';
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  bool get _apiKeyMissing => _apiKey.isEmpty;

  @override
  void initState() {
    super.initState();
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_apiKeyMissing) {
      return _buildApiKeyMissingScreen(context);
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.1),
              scheme.surface,
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildImageSection(context),
                        const SizedBox(height: 24),
                        _buildActionButtons(context),
                        const SizedBox(height: 24),
                        if (_isAnalyzing) _buildAnalyzingWidget(context),
                        if (_analysisResult != null)
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildAnalysisResults(context),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meal Photo Analysis',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'NutriCore',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.surface, scheme.surface.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _selectedImage != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = null;
                        _analysisResult = null;
                        _resetCorrectionState();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.scrim.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 0.1),
                        scheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    size: 64,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Capture Your Meal',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Take a photo and analyze the nutritional content instantly',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.camera_alt,
            label: 'Camera',
            gradient: [
              scheme.primary,
              scheme.primary.withValues(alpha: 0.8),
            ],
            onPressed: () => _pickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.photo_library,
            label: 'Gallery',
            gradient: [
              scheme.secondary,
              scheme.secondary.withValues(alpha: 0.8),
            ],
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingWidget(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.1),
                  scheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: CircularProgressIndicator(
              color: scheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing your meal...',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Identifying ingredients and calculating nutrition',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.tertiary.withValues(alpha: 0.05),
            scheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: scheme.tertiary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(context),
          const SizedBox(height: 20),
          _buildMealInfo(context),
          const SizedBox(height: 16),
          _buildPortionEditor(context),
          if (_offPer100 != null || _checkingOff) ...[
            const SizedBox(height: 12),
            _buildOffMatchBanner(context),
          ],
          const SizedBox(height: 16),
          _buildNutritionGrid(context),
          if (_analysisResult!['ingredients'] != null) ...[
            const SizedBox(height: 20),
            _buildIngredientsSection(context),
          ],
          const SizedBox(height: 24),
          _buildAddToLogButton(context),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.tertiary,
                scheme.tertiary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.psychology, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis Complete!',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.tertiary,
                ),
              ),
              Text(
                'Detected nutritional information',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        if (_confidence != 'unknown') _buildConfidenceChip(context),
      ],
    );
  }

  Widget _buildConfidenceChip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    late final Color color;
    late final IconData icon;
    switch (_confidence) {
      case 'high':
        color = scheme.primary;
        icon = Icons.check_circle_rounded;
        break;
      case 'medium':
        color = scheme.tertiary;
        icon = Icons.help_outline_rounded;
        break;
      case 'low':
      default:
        color = scheme.error;
        icon = Icons.warning_amber_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _confidence,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortionEditor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mults = const [0.5, 1.0, 1.5, 2.0];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.scale_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Adjust portion',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${_currentGrams.round()} g',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'AI guessed ${_estimatedGrams.round()} g. Tap or drag to correct.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: mults.map((m) {
              final target = _estimatedGrams * m;
              final selected = (_currentGrams - target).abs() < 0.5;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _pickMultiplier(m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? scheme.primary
                            : scheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? scheme.primary
                              : scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${m.toStringAsFixed(m == m.roundToDouble() ? 0 : 1)}×',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? scheme.onPrimary
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Slider(
            min: 10,
            max: (_estimatedGrams * 3).clamp(200.0, 1500.0),
            value: _currentGrams.clamp(
              10.0,
              (_estimatedGrams * 3).clamp(200.0, 1500.0),
            ),
            onChanged: (v) => _setGrams(v),
          ),
        ],
      ),
    );
  }

  Widget _buildOffMatchBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (_checkingOff && _offPer100 == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Cross-checking with OpenFoodFacts…',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }
    if (_offPer100 == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, color: scheme.secondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _useOff ? 'Using OpenFoodFacts data' : 'OpenFoodFacts match found',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.secondary,
                  ),
                ),
                if (_offMatchName != null)
                  Text(
                    _offMatchName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: _useOff,
            onChanged: (v) => setState(() => _useOff = v),
          ),
        ],
      ),
    );
  }

  Widget _buildMealInfo(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant_menu, color: scheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _analysisResult!['meal_name'] ?? 'Detected Meal',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                if (_analysisResult!['portion_size'] != null)
                  Text(
                    'Portion: ${_analysisResult!['portion_size']}',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionGrid(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nutritionItems = [
      {
        'icon': '🔥',
        'label': 'Calories',
        'value': _scaled('calories').round().toString(),
        'unit': 'kcal',
        'color': scheme.primary,
      },
      {
        'icon': '💪',
        'label': 'Protein',
        'value': _scaled('protein').toStringAsFixed(1),
        'unit': 'g',
        'color': scheme.primary,
      },
      {
        'icon': '🌾',
        'label': 'Carbs',
        'value': _scaled('carbs').toStringAsFixed(1),
        'unit': 'g',
        'color': scheme.tertiary,
      },
      {
        'icon': '🥑',
        'label': 'Fat',
        'value': _scaled('fat').toStringAsFixed(1),
        'unit': 'g',
        'color': scheme.secondary,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: nutritionItems.length,
      itemBuilder: (context, index) {
        final item = nutritionItems[index];
        return _buildNutritionCard(
          context,
          item['icon'] as String,
          item['label'] as String,
          item['value'] as String,
          item['unit'] as String,
          item['color'] as Color,
        );
      },
    );
  }

  Widget _buildNutritionCard(
    BuildContext context,
    String icon,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: scheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Detected Ingredients',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _analysisResult!['ingredients'].toString(),
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToLogButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.tertiary, scheme.tertiary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.tertiary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addToNutritionLog,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Add to Nutrition Log',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
          _resetCorrectionState();
        });

        // Auto-analyze after picking image
        _analyzeImage();
      }
    } catch (e) {
      CustomThemeFlushbar.show(
        title: 'Error',
        message: 'Failed to pick image: ${e.toString()}',
      );
    }
  }

  void _addToNutritionLog() {
    if (_analysisResult == null) return;
    final ingredients =
        _analysisResult!['ingredients']?.toString().trim() ?? '';
    final noteParts = <String>[
      '${_currentGrams.round()}g portion',
      if (_useOff && _offMatchName != null) 'OpenFoodFacts: $_offMatchName',
      if (ingredients.isNotEmpty) ingredients,
    ];
    final existing = <String, dynamic>{
      'name': _analysisResult!['meal_name'] ?? 'Analyzed Meal',
      'calories': _scaled('calories').round(),
      'proteins': _scaled('protein'),
      'carbs': _scaled('carbs'),
      'fat': _scaled('fat'),
      'type': 'meal',
      'notes': noteParts.join(' · '),
      'favorite': false,
    };
    AddManualMealSheet.show(context, existing: existing);
  }

  void _resetCorrectionState() {
    _estimatedGrams = 100;
    _currentGrams = 100;
    _confidence = 'unknown';
    _offPer100 = null;
    _offMatchName = null;
    _useOff = false;
    _checkingOff = false;
  }

  void _applyAnalysis(Map<String, dynamic> data) {
    final est = (data['estimated_grams'] is num)
        ? (data['estimated_grams'] as num).toDouble().clamp(1.0, 3000.0)
        : 100.0;
    final conf = (data['confidence'] as String?)?.toLowerCase() ?? 'unknown';
    setState(() {
      _analysisResult = data;
      _estimatedGrams = est;
      _currentGrams = est;
      _confidence = (['low', 'medium', 'high'].contains(conf))
          ? conf
          : 'unknown';
      _offPer100 = null;
      _offMatchName = null;
      _useOff = false;
    });
    final name = (data['meal_name'] as String?)?.trim();
    if (name != null && name.length >= 3) {
      _crossCheckOpenFoodFacts(name);
    }
  }

  // Scaled macros: per-gram baseline × current grams. Source flips between
  // the model's estimate and the OpenFoodFacts match when [_useOff] is on.
  double _modelTotal(String key) {
    final v = _analysisResult?[key];
    if (v is num) return v.toDouble();
    return 0.0;
  }

  double _perGram(String key) {
    if (_useOff && _offPer100 != null) {
      final off = _offPer100![key] ?? 0.0;
      return off / 100.0;
    }
    final total = _modelTotal(key);
    if (_estimatedGrams <= 0) return 0.0;
    return total / _estimatedGrams;
  }

  double _scaled(String key) => _perGram(key) * _currentGrams;

  void _setGrams(double g) {
    setState(() {
      _currentGrams = g.clamp(1.0, 3000.0);
    });
  }

  void _pickMultiplier(double m) => _setGrams(_estimatedGrams * m);

  Future<void> _crossCheckOpenFoodFacts(String mealName) async {
    setState(() => _checkingOff = true);
    try {
      final result = await off.OpenFoodAPIClient.searchProducts(
        null,
        off.ProductSearchQueryConfiguration(
          parametersList: [
            off.SearchTerms(terms: [mealName]),
            const off.PageSize(size: 5),
          ],
          fields: const [
            off.ProductField.NAME,
            off.ProductField.BRANDS,
            off.ProductField.NUTRIMENTS,
          ],
          language: off.OpenFoodFactsLanguage.ENGLISH,
          version: const off.ProductQueryVersion(2),
        ),
      );
      if (!mounted) return;
      final products = result.products ?? const [];
      for (final p in products) {
        final kcal = p.nutriments
            ?.getValue(off.Nutrient.energyKCal, off.PerSize.oneHundredGrams);
        if (kcal == null || kcal <= 0) continue;
        final protein = p.nutriments
                ?.getValue(off.Nutrient.proteins, off.PerSize.oneHundredGrams) ??
            0.0;
        final carbs = p.nutriments
                ?.getValue(
                    off.Nutrient.carbohydrates, off.PerSize.oneHundredGrams) ??
            0.0;
        final fat = p.nutriments
                ?.getValue(off.Nutrient.fat, off.PerSize.oneHundredGrams) ??
            0.0;
        setState(() {
          _offPer100 = {
            'calories': kcal.toDouble(),
            'protein': protein.toDouble(),
            'carbs': carbs.toDouble(),
            'fat': fat.toDouble(),
          };
          _offMatchName = p.productName ?? mealName;
        });
        break;
      }
    } catch (e) {
      if (kDebugMode) print('OFF cross-check error: $e');
    } finally {
      if (mounted) setState(() => _checkingOff = false);
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();

      final prompt = '''
Analyze this meal image and return ONLY a JSON object — no prose, no
markdown — with this exact shape:
{
  "meal_name": "Short name of the dish",
  "estimated_grams": 0,
  "confidence": "low" | "medium" | "high",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "fiber": 0,
  "sugar": 0,
  "sodium": 0,
  "ingredients": "Comma-separated main ingredients",
  "portion_size": "Plain-language portion description",
  "health_notes": "One-line health note"
}

Rules:
- "estimated_grams" is the total mass of food visible (NOT plate/bowl).
- All nutrient values are for the ENTIRE portion (not per 100g).
- "confidence" reflects how sure you are about identity AND portion:
  - "high" only when dish is unambiguous and portion has a clear reference.
  - "low" when the dish is mixed/occluded or scale is ambiguous.
- Integers for calories/estimated_grams; decimals allowed for macros.
''';

      if (_apiKeyMissing) {
        throw Exception('AI features are not configured.');
      }
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _visionModel,
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': prompt},
                    {
                      'type': 'image_url',
                      'image_url': {'url': dataUrl},
                    },
                  ],
                },
              ],
              'max_tokens': 600,
              'temperature': 0.2,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (res.statusCode != 200) {
        throw Exception('Groq ${res.statusCode}: ${res.body}');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = body['choices'] as List?;
      final msg = (choices != null && choices.isNotEmpty)
          ? choices.first['message'] as Map<String, dynamic>?
          : null;
      final responseText = msg?['content'] as String?;

      if (responseText != null) {
        String jsonString = responseText.trim();

        const String jsonMarker = '```.json';
        const String codeMarker = '```';

        if (jsonString.contains(jsonMarker)) {
          final startIndex = jsonString.indexOf(jsonMarker) + jsonMarker.length;
          final endIndex = jsonString.lastIndexOf(codeMarker);
          if (startIndex < endIndex) {
            jsonString = jsonString.substring(startIndex, endIndex).trim();
          }
        } else if (jsonString.contains(codeMarker)) {
          final startIndex = jsonString.indexOf(codeMarker) + codeMarker.length;
          final endIndex = jsonString.lastIndexOf(codeMarker);
          if (startIndex < endIndex) {
            jsonString = jsonString.substring(startIndex, endIndex).trim();
          }
        }

        if (!jsonString.startsWith('{')) {
          final jsonStart = jsonString.indexOf('{');
          final jsonEnd = jsonString.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
            jsonString = jsonString.substring(jsonStart, jsonEnd + 1);
          }
        }

        if (kDebugMode) {
          print('🔍 Extracted JSON: $jsonString');
        }

        try {
          final analysisData = jsonDecode(jsonString) as Map<String, dynamic>;
          _applyAnalysis(analysisData);
          _animationController.reset();
          _animationController.forward();

          CustomThemeFlushbar.show(
            title: 'Analysis Complete',
            message: 'Your meal has been analyzed successfully',
          );

          if (kDebugMode) {
            print(
              'Successfully parsed response: ${analysisData['meal_name']}',
            );
          }
        } catch (jsonError) {
          if (kDebugMode) {
            print('JSON Parse Error: $jsonError');
          }
          if (kDebugMode) {
            print('Attempted to parse: $jsonString');
          }
          _parseResponseManually(responseText);
        }
      } else {
        throw Exception('No response from analysis');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analysis Error: $e');
      }
      CustomThemeFlushbar.show(
        title: 'Analysis Failed',
        message: 'Could not analyze the image. Please try again.',
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _parseResponseManually(String responseText) {
    try {
      final caloriesMatch = RegExp(
        r'"calories":\s*(\d+)',
      ).firstMatch(responseText);
      final proteinMatch = RegExp(
        r'"protein":\s*([\d.]+)',
      ).firstMatch(responseText);
      final carbsMatch = RegExp(
        r'"carbs":\s*([\d.]+)',
      ).firstMatch(responseText);
      final fatMatch = RegExp(r'"fat":\s*([\d.]+)').firstMatch(responseText);
      final fiberMatch = RegExp(
        r'"fiber":\s*([\d.]+)',
      ).firstMatch(responseText);
      final sugarMatch = RegExp(
        r'"sugar":\s*([\d.]+)',
      ).firstMatch(responseText);
      final sodiumMatch = RegExp(
        r'"sodium":\s*([\d.]+)',
      ).firstMatch(responseText);
      final mealNameMatch = RegExp(
        r'"meal_name":\s*"([^"]+)"',
      ).firstMatch(responseText);
      final ingredientsMatch = RegExp(
        r'"ingredients":\s*"([^"]+)"',
      ).firstMatch(responseText);

      final manualResult = {
        'meal_name': mealNameMatch?.group(1) ?? 'Analyzed Meal',
        'calories': int.tryParse(caloriesMatch?.group(1) ?? '0') ?? 0,
        'protein': double.tryParse(proteinMatch?.group(1) ?? '0') ?? 0.0,
        'carbs': double.tryParse(carbsMatch?.group(1) ?? '0') ?? 0.0,
        'fat': double.tryParse(fatMatch?.group(1) ?? '0') ?? 0.0,
        'fiber': double.tryParse(fiberMatch?.group(1) ?? '0') ?? 0.0,
        'sugar': double.tryParse(sugarMatch?.group(1) ?? '0') ?? 0.0,
        'sodium': double.tryParse(sodiumMatch?.group(1) ?? '0') ?? 0.0,
        'ingredients': ingredientsMatch?.group(1) ?? 'Various ingredients',
      };

      _applyAnalysis(manualResult);

      CustomThemeFlushbar.show(
        title: 'Analysis Complete',
        message: 'Your meal has been analyzed successfully',
      );

      if (kDebugMode) {
        print('Manual parsing successful: ${manualResult['meal_name']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Manual parsing also failed: $e');
      }
      CustomThemeFlushbar.show(
        title: 'Analysis Failed',
        message: 'Could not parse the response. Please try again.',
      );
    }
  }

  Widget _buildApiKeyMissingScreen(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  size: 34,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AI Meal Analysis is not configured',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A Groq API key is required to analyse meals from a photo. Add GROQ_API_KEY to your .env to enable this feature.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Get.back(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
