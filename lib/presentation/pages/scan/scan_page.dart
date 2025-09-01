import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/presentation/controllers/main_controller.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../controllers/scan_controller.dart'; // 🔥 ADDED
import '../../widgets/product_details_sheet.dart';

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
      detectionSpeed: DetectionSpeed.noDuplicates,
      autoStart: false,
      formats: [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
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
          Future.delayed(Duration(milliseconds: 500), () {
            _startCameraDelayed();
          });
        }
        break;
    }
  }

  Future<void> _startCameraDelayed() async {
    await Future.delayed(Duration(milliseconds: 200));
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
        print('▶️ Starting camera...');
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
    await Future.delayed(Duration(milliseconds: 200));
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            fit: BoxFit.cover,
            controller: cameraController,
            onDetect: _onBarcodeDetected,
          ),

          _buildCustomOverlay(),
          _buildTopAppBar(),
          _buildBottomPanel(),

          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCustomOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: ScannerOverlayShape(
          borderColor: AppColors.primary,
          borderLength: 50,
          borderWidth: 4,
          cutOutSize: 280,
          overlayColor: Colors.black.withOpacity(0.7),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 200),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Point camera at barcode',
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (isLoading || !_isCameraRunning || _isOperationInProgress) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    if (!_isValidFoodBarcode(barcode)) {
      _showInvalidBarcodeMessage(barcode);
      return;
    }

    if (scannedCodes.contains(barcode)) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      scannedBarcode = barcode;
      isLoading = true;
    });

    scanController
        .scanBarcode(barcode)
        .then((_) {
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              isLoading = false;
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
    });

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

  // calories using ScanController
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

  Widget _buildTopAppBar() {
    return SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              _buildGlassButton(
                icon: Icons.close,
                onPressed: () => Get.find<MainController>().changeIndex(0),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Product Scanner',
                        style: AppTextStyles.headingMedium(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (scannedCodes.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${scannedCodes.length} scanned',
                            style: AppTextStyles.labelSmall(
                              context,
                            ).copyWith(color: AppColors.primary),
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
                  SizedBox(width: 8),
                  _buildGlassButton(
                    icon: Icons.clear_all,
                    onPressed: () => scanController.clearAllHistory(),
                  ),
                  SizedBox(width: 8),
                  _buildGlassButton(
                    icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.9), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentProduct != null) _buildLastScannedCard(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.keyboard_outlined,
                      label: 'Manual',
                      color: AppColors.info,
                      onPressed: _showManualInput,
                    ),
                    _buildActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Reset',
                      color: AppColors.secondary,
                      onPressed: _resetScanner,
                    ),
                    _buildActionButton(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Save All',
                      color: AppColors.success,
                      onPressed: _saveAllToFirebase,
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

  Widget _buildLastScannedCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: currentProduct!.imageFrontUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      currentProduct!.imageFrontUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.fastfood, color: AppColors.primary),
                    ),
                  )
                : Icon(Icons.fastfood, color: AppColors.primary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentProduct!.productName ?? 'Unknown Product',
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Barcode: $scannedBarcode',
                  style: AppTextStyles.labelMedium(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  '${_getCalories(currentProduct!)} kcal per 100g',
                  style: AppTextStyles.labelMedium(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showProductDetails(currentProduct!),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.visibility, color: Colors.white, size: 20),
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
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge.toString(),
                style: TextStyle(
                  color: Colors.white,
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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelMedium(
                context,
              ).copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Looking up product...',
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                'Please wait while we fetch nutrition info',
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary),
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
      if (kDebugMode) print('Valid food barcode: $code');
      return true;
    }
    if (kDebugMode) print('Not a recognized food product barcode: $code');
    return false;
  }

  bool _isKnownFoodBarcodePattern(String code) {
    final foodPrefixes = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '50',
      '51',
      '52',
      '53',
      '54',
      '55',
      '56',
      '57',
      '58',
      '59',
      '60',
      '61',
      '62',
      '63',
      '64',
      '65',
      '66',
      '67',
      '68',
      '69',
      '70',
      '71',
      '72',
      '73',
      '74',
      '75',
      '76',
      '77',
      '78',
      '79',
      '500',
      '501',
      '502',
      '503',
      '504',
      '505',
      '506',
      '507',
      '508',
      '509',
      '890',
      '891',
      '892',
      '893',
      '894',
      '895',
      '896',
      '897',
      '898',
      '899',
      '93',
      '94',
      '45',
      '49',
    ];

    for (String prefix in foodPrefixes) {
      if (code.startsWith(prefix)) return true;
    }
    return _hasValidChecksum(code);
  }

  bool _hasValidChecksum(String code) {
    if (code.length != 13 && code.length != 12 && code.length != 8)
      return false;

    try {
      List<int> digits = code.split('').map((e) => int.parse(e)).toList();
      int sum = 0;

      if (code.length == 13) {
        for (int i = 0; i < 12; i++) {
          sum += digits[i] * (i % 2 == 0 ? 1 : 3);
        }
        int checkDigit = (10 - (sum % 10)) % 10;
        return checkDigit == digits[12];
      }

      if (code.length == 12) {
        for (int i = 0; i < 11; i++) {
          sum += digits[i] * (i % 2 == 0 ? 3 : 1);
        }
        int checkDigit = (10 - (sum % 10)) % 10;
        return checkDigit == digits[11];
      }

      if (code.length == 8) {
        for (int i = 0; i < 7; i++) {
          sum += digits[i] * (i % 2 == 0 ? 3 : 1);
        }
        int checkDigit = (10 - (sum % 10)) % 10;
        return checkDigit == digits[7];
      }

      return true;
    } catch (e) {
      if (kDebugMode) print('Checksum validation error: $e');
      return false;
    }
  }

  void _showInvalidBarcodeMessage(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Invalid food barcode: $code')),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: Duration(seconds: 2),
      ),
    );
    HapticFeedback.lightImpact();
  }

  void _showManualInput() {
    final TextEditingController controller = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Enter Barcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter product barcode',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.qr_code, color: AppColors.primary),
                helperText: 'Enter 8-13 digit barcode number',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final barcode = controller.text.trim();
              if (barcode.isNotEmpty && _isValidFoodBarcode(barcode)) {
                Get.back();
                setState(() {
                  scannedBarcode = barcode;
                  isLoading = true;
                });
                scanController.scanBarcode(barcode).then((_) {
                  if (mounted) {
                    setState(() {
                      isLoading = false;
                    });
                  }
                });
              } else {
                Get.snackbar(
                  'Invalid Barcode',
                  'Please enter a valid food product barcode',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAllToFirebase() async {
    if (recentProducts.isEmpty) {
      Get.snackbar(
        'No Products',
        'No products to save',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      CustomThemeFlushbar(
        title: 'Saving...',
        message: 'Saving ${recentProducts.length} products to Firebase',
      );
      scanController.refreshRecentProducts();

      CustomThemeFlushbar(
        title: 'Success',
        message: '${recentProducts.length} products saved successfully',
      );
    } catch (e) {
      CustomThemeFlushbar(
        title: 'Save Failed',
        message: 'Failed to save products: ${e.toString()}',
      );
    }
  }

  void _showScanHistory() {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Scan History',
                    style: AppTextStyles.headingMedium(context),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: recentProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No products scanned yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: recentProducts.length,
                      itemBuilder: (context, index) {
                        final product = recentProducts[index];
                        return ListTile(
                          leading: product.imageFrontUrl != null
                              ? Image.network(
                                  product.imageFrontUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.fastfood),
                                )
                              : Icon(Icons.fastfood),
                          title: Text(product.productName ?? 'Unknown Product'),
                          subtitle: Text(product.brands ?? ''),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
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
    Get.bottomSheet(
      ProductDetailsSheet(product: product),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    Path outerPath = Path()..addRect(rect);
    Path innerPath = getInnerPath(rect, textDirection: textDirection);
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
