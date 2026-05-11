import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/presentation/controllers/main_controller.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../../controllers/scan_controller.dart';
import '../../widgets/product_details_sheet.dart';
import '../../widgets/shared/add_to_meal_sheet.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  ScanPageState createState() => ScanPageState();
}

class ScanPageState extends State<ScanPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late final MobileScannerController cameraController;
  final mainController = Get.find<MainController>();
  late final ScanController scanController;

  String scannedBarcode = '';
  bool isLoading = false;
  bool isFlashOn = false;

  bool _isCameraRunning = false;
  bool _isOperationInProgress = false;

  Product? currentProduct;
  List<Product> recentProducts = [];
  List<String> scannedCodes = [];

  // 2-frame confirmation
  String? _lastDetectedCode;
  int _sameCodeFrames = 0;

  // Looking-up pill state
  String? _lookingUpCode;

  // Not-found state
  String _lookupError = '';

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    scanController = Get.find<ScanController>();

    cameraController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.normal,
      autoStart: false,
      cameraResolution: const Size(1920, 1080),
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.itf,
      ],
    );

    _setupOpenFoodFacts();
    _loadRecentProducts();

    ever(scanController.recentProducts, (products) {
      if (mounted) {
        setState(() {
          recentProducts = products.toList();
        });
      }
    });

    ever(scanController.scannedCodes, (codes) {
      if (mounted) {
        setState(() {
          scannedCodes = codes.toList();
        });
      }
    });

    ever(scanController.currentProduct, (product) {
      if (mounted && product != null) {
        setState(() {
          currentProduct = product;
        });
      }
    });

    ever(scanController.lookupError, (err) {
      if (mounted) {
        setState(() {
          _lookupError = err;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mainController.currentIndex.value == 2) {
        _startCameraDelayed();
      }
    });

    ever(mainController.currentIndex, (index) {
      if (index == 2) {
        _startCameraDelayed();
      } else {
        _stopCameraDelayed();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (kDebugMode) {
          print('App paused - stopping camera');
        }
        _stopCameraDelayed();
        break;
      case AppLifecycleState.resumed:
        if (kDebugMode) {
          print('App resumed - checking camera state');
        }
        if (mainController.currentIndex.value == 2) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _startCameraDelayed();
          });
        }
        break;
    }
  }

  Future<void> _startCameraDelayed() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    if (_isOperationInProgress || _isCameraRunning) {
      if (kDebugMode) {
        print('Camera already starting or running');
      }
      return;
    }

    try {
      _isOperationInProgress = true;
      if (kDebugMode) {
        print('Starting camera...');
      }

      await cameraController.start();

      if (mounted) {
        setState(() {
          _isCameraRunning = true;
        });
      }
      if (kDebugMode) {
        print('Camera started successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Camera start error: $e');
      }
      if (e.toString().contains('already started')) {
        if (mounted) {
          setState(() {
            _isCameraRunning = true;
          });
        }
      }
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<void> _stopCameraDelayed() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    if (_isOperationInProgress || !_isCameraRunning) {
      if (kDebugMode) {
        print('Camera already stopped or stopping');
      }
      return;
    }

    try {
      _isOperationInProgress = true;
      if (kDebugMode) {
        print('Stopping camera...');
      }

      await cameraController.stop();

      if (mounted) {
        setState(() {
          _isCameraRunning = false;
        });
      }
      if (kDebugMode) {
        print('Camera stopped successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Camera stop error: $e');
      }
      if (mounted) {
        setState(() {
          _isCameraRunning = false;
        });
      }
    } finally {
      _isOperationInProgress = false;
    }
  }

  void _disposeCamera() {
    try {
      cameraController.dispose();
      _isCameraRunning = false;
      _isOperationInProgress = false;
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing camera: $e');
      }
    }
  }

  void _setupOpenFoodFacts() {
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'NutriCheck',
      version: '1.0.0',
      system: 'Flutter App',
    );
    OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
      OpenFoodFactsLanguage.ENGLISH,
    ];
    OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.INDIA;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            fit: BoxFit.contain,
            controller: cameraController,
            onDetect: _onBarcodeDetected,
          ),

          _buildCustomOverlay(scheme),
          _buildTopAppBar(scheme),
          _buildLookingUpPill(scheme),
          _buildBottomPanel(scheme),

          if (isLoading) _buildLoadingOverlay(scheme),
        ],
      ),
    );
  }

  Widget _buildCustomOverlay(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: ShapeDecoration(
        shape: ScannerOverlayShape(
          borderColor: scheme.primary,
          borderLength: 50,
          borderWidth: 4,
          cutOutSize: 280,
          overlayColor: Colors.black.withValues(alpha: 0.7),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 200),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Point camera at barcode',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLookingUpPill(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Positioned(
      top: kToolbarHeight + 32,
      left: 24,
      right: 24,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _lookingUpCode == null
            ? const SizedBox.shrink(key: ValueKey('empty'))
            : Center(
                key: const ValueKey('pill'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            scheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Barcode detected . looking up',
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (isLoading || !_isCameraRunning || _isOperationInProgress) return;

    final raw = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (raw == null || raw.isEmpty) return;

    // 2-frame confirmation
    if (_lastDetectedCode != raw) {
      _lastDetectedCode = raw;
      _sameCodeFrames = 1;
      return;
    }
    _sameCodeFrames++;
    if (_sameCodeFrames < 2) return;
    _sameCodeFrames = 0;

    if (!_isValidFoodBarcode(raw)) {
      _showInvalidBarcodeMessage(raw);
      return;
    }

    if (scannedCodes.contains(raw)) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      scannedBarcode = raw;
      isLoading = true;
      _lookingUpCode = raw;
    });

    scanController
        .scanBarcode(raw)
        .then((_) {
          if (mounted) {
            setState(() {
              isLoading = false;
              _lookingUpCode = null;
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              isLoading = false;
              _lookingUpCode = null;
            });
          }
        });
  }

  void _toggleFlash() {
    if (_isCameraRunning && !_isOperationInProgress) {
      cameraController.toggleTorch();
      setState(() {
        isFlashOn = !isFlashOn;
      });
    }
  }

  void _resetScanner() {
    setState(() {
      scannedBarcode = '';
      currentProduct = null;
      _lastDetectedCode = null;
      _sameCodeFrames = 0;
      _lookingUpCode = null;
    });
    scanController.lookupError.value = '';

    if (!_isCameraRunning && mainController.currentIndex.value == 2) {
      _startCameraDelayed();
    }
  }

  Future<void> _loadRecentProducts() async {
    try {
      scanController.refreshRecentProducts();
      if (mounted) {
        setState(() {
          recentProducts = scanController.recentProducts.toList();
          scannedCodes = scanController.scannedCodes.toList();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recent products: $e');
      }
    }
  }

  int _getCalories(Product product) {
    try {
      return product.nutriments
              ?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams)
              ?.toInt() ??
          0;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildTopAppBar(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              _buildGlassButton(
                icon: Icons.close,
                onPressed: () {
                  if (Get.isRegistered<MainController>()) {
                    Get.find<MainController>().changeIndex(0);
                  }
                },
              ),
              Expanded(
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Product Scanner',
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (scannedCodes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${scannedCodes.length} scanned',
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _buildGlassButton(
                    icon: Icons.history,
                    onPressed: _showScanHistory,
                    badge: recentProducts.length,
                  ),
                  const SizedBox(width: 8),
                  _buildGlassButton(
                    icon: Icons.clear_all,
                    onPressed: () => scanController.clearAllHistory(),
                  ),
                  const SizedBox(width: 8),
                  _buildGlassButton(
                    icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(ColorScheme scheme) {
    final showNotFound =
        _lookupError.isNotEmpty && scanController.currentProduct.value == null;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showNotFound) _buildNotFoundCard(scheme),
                if (currentProduct != null) _buildLastScannedCard(scheme),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.keyboard_outlined,
                      label: 'Manual',
                      color: scheme.tertiary,
                      onPressed: _showManualInput,
                    ),
                    _buildActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Reset',
                      color: scheme.secondary,
                      onPressed: _resetScanner,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundCard(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: scheme.error, size: 36),
          const SizedBox(height: 8),
          Text(
            'Not in our database',
            style: textTheme.titleSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try searching by name instead',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              scanController.lookupError.value = '';
              if (Get.isRegistered<MainController>()) {
                Get.find<MainController>().changeIndex(1);
              }
            },
            child: Text(
              'Open search',
              style: textTheme.labelLarge?.copyWith(color: scheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastScannedCard(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 50,
              height: 50,
              child: CachedNetworkImage(
                imageUrl: currentProduct!.imageFrontSmallUrl ??
                    currentProduct!.imageFrontUrl ??
                    '',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: scheme.primary.withValues(alpha: 0.08),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: scheme.primary.withValues(alpha: 0.08),
                  child: Icon(
                    Icons.fastfood_rounded,
                    color: scheme.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentProduct!.productName ?? 'Unknown Product',
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Barcode: $scannedBarcode',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                Text(
                  '${_getCalories(currentProduct!)} kcal per 100g',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Quick log pill
          Material(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => AddToMealSheet.show(context, currentProduct!),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: scheme.onPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Log',
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showProductDetails(currentProduct!),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.visibility,
                color: scheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    int? badge,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 24),
        ),
        if (badge != null && badge > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge.toString(),
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'Looking up product...',
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Please wait while we fetch nutrition info',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isValidFoodBarcode(String code) {
    code = code.trim();
    if (code.isEmpty) return false;
    if (code.length < 8 || code.length > 14) return false;
    final numericRegex = RegExp(r'^[0-9]+$');
    if (!numericRegex.hasMatch(code)) return false;
    if (_isKnownFoodBarcodePattern(code)) {
      if (kDebugMode) {
        print('Valid food barcode: $code');
      }
      return true;
    }
    if (kDebugMode) {
      print('Not a recognized food product barcode: $code');
    }
    return false;
  }

  bool _isKnownFoodBarcodePattern(String code) {
    final foodPrefixes = [
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
      '50', '51', '52', '53', '54', '55', '56', '57', '58', '59',
      '60', '61', '62', '63', '64', '65', '66', '67', '68', '69',
      '70', '71', '72', '73', '74', '75', '76', '77', '78', '79',
      '500', '501', '502', '503', '504', '505', '506', '507', '508', '509',
      '890', '891', '892', '893', '894', '895', '896', '897', '898', '899',
      '93', '94', '45', '49',
    ];

    for (String prefix in foodPrefixes) {
      if (code.startsWith(prefix)) return true;
    }
    return _hasValidChecksum(code);
  }

  bool _hasValidChecksum(String code) {
    if (code.length != 13 && code.length != 12 && code.length != 8) {
      return false;
    }

    try {
      final List<int> digits = code.split('').map((e) => int.parse(e)).toList();
      int sum = 0;

      if (code.length == 13) {
        for (int i = 0; i < 12; i++) {
          sum += digits[i] * (i % 2 == 0 ? 1 : 3);
        }
        final int checkDigit = (10 - (sum % 10)) % 10;
        return checkDigit == digits[12];
      }

      if (code.length == 12) {
        for (int i = 0; i < 11; i++) {
          sum += digits[i] * (i % 2 == 0 ? 3 : 1);
        }
        final int checkDigit = (10 - (sum % 10)) % 10;
        return checkDigit == digits[11];
      }

      if (code.length == 8) {
        for (int i = 0; i < 7; i++) {
          sum += digits[i] * (i % 2 == 0 ? 3 : 1);
        }
        final int checkDigit = (10 - (sum % 10)) % 10;
        return checkDigit == digits[7];
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Checksum validation error: $e');
      }
      return false;
    }
  }

  void _showInvalidBarcodeMessage(String code) {
    CustomThemeFlushbar.show(
      title: 'Invalid barcode',
      message: "That code ($code) isn't a valid food product barcode.",
    );
    HapticFeedback.lightImpact();
  }

  void _showManualInput() {
    final TextEditingController controller = TextEditingController();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter barcode',
                  style: textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                  ],
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    hintText: 'Enter product barcode',
                    prefixIcon: Icon(
                      Icons.qr_code_rounded,
                      color: scheme.primary,
                    ),
                    helperText: '8-13 digit code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: scheme.primary, width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: scheme.onSurface.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: textTheme.labelLarge?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final barcode = controller.text.trim();
                          if (barcode.isNotEmpty &&
                              _isValidFoodBarcode(barcode)) {
                            Navigator.of(sheetCtx).pop();
                            setState(() {
                              scannedBarcode = barcode;
                              isLoading = true;
                              _lookingUpCode = barcode;
                            });
                            scanController.scanBarcode(barcode).then((_) {
                              if (mounted) {
                                setState(() {
                                  isLoading = false;
                                  _lookingUpCode = null;
                                });
                              }
                            }).catchError((_) {
                              if (mounted) {
                                setState(() {
                                  isLoading = false;
                                  _lookingUpCode = null;
                                });
                              }
                            });
                          } else {
                            CustomThemeFlushbar.show(
                              title: 'Invalid barcode',
                              message:
                                  'Please enter a valid food product barcode.',
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Look up',
                          style: textTheme.labelLarge?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showScanHistory() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Scan History',
                    style: textTheme.titleLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close, color: scheme.onSurface),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: scheme.onSurface.withValues(alpha: 0.08),
            ),
            Expanded(
              child: recentProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: scheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No products scanned yet',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: recentProducts.length,
                      itemBuilder: (context, index) {
                        final product = recentProducts[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: CachedNetworkImage(
                                imageUrl: product.imageFrontSmallUrl ??
                                    product.imageFrontUrl ??
                                    '',
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: scheme.primary
                                      .withValues(alpha: 0.08),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: scheme.primary
                                      .withValues(alpha: 0.08),
                                  child: Icon(
                                    Icons.fastfood_rounded,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            product.productName ?? 'Unknown Product',
                            style: textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            product.brands ?? '',
                            style: textTheme.bodySmall?.copyWith(
                              color:
                                  scheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                          onTap: () => _showProductDetails(product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ProductDetailsSheet(product: product),
    );
  }
}

class ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double cutOutSize;
  final Color overlayColor;

  const ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.borderLength = 30,
    required this.cutOutSize,
    this.overlayColor = const Color(0x88000000),
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
        const Radius.circular(12),
      ),
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final Path outerPath = Path()..addRect(rect);
    final Path innerPath = getInnerPath(rect, textDirection: textDirection);
    return Path.combine(PathOperation.difference, outerPath, innerPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect, textDirection: textDirection), paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final path = Path();

    // Top-left
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top);
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    // Top-right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom-left
    path.moveTo(cutOutRect.left, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.bottom);
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.bottom);

    // Bottom-right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.right, cutOutRect.bottom);
    path.lineTo(cutOutRect.right, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderLength: borderLength,
      cutOutSize: cutOutSize,
    );
  }
}
