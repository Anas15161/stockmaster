import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';

class ScanScreen extends StatefulWidget {
  final bool isVisible;

  const ScanScreen({super.key, this.isVisible = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  // MobileScannerController handles the camera.
  late final MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      // Throttle detection to once per second to reduce CPU usage and buffer pressure
      detectionTimeoutMs: 1000,
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
      autoStart: false,
      // Limit formats to common product codes and QR codes to speed up analysis
      formats: [
        BarcodeFormat.qrCode,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
      ],
    );
    if (widget.isVisible) {
      controller.start();
    }
  }

  @override
  void didUpdateWidget(covariant ScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible) {
      controller.start();
    } else if (oldWidget.isVisible && !widget.isVisible) {
      controller.stop();
    }
  }

  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return; // Prevent multiple navigations

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String code = barcode.rawValue!;
        _processCode(code);
        break; 
      }
    }
  }

  Future<void> _processCode(String rawCode) async {
    setState(() {
      _isProcessing = true;
    });

    // Stop camera to release buffers and prevent "Unable to acquire a buffer item" warning
    await controller.stop();

    String skuToCheck = rawCode;
    Product? scannedProduct;

    // Try to parse as JSON
    try {
      final decoded = jsonDecode(rawCode);
      if (decoded is Map<String, dynamic>) {
        // Extract SKU if available
        if (decoded.containsKey('sku')) {
          skuToCheck = decoded['sku'].toString();
        }

        // Handle images (can be String or List)
        List<String> imageList = [];
        if (decoded.containsKey('images')) {
          var imagesData = decoded['images'];
          if (imagesData is List) {
            imageList = List<String>.from(imagesData);
          } else if (imagesData is String) {
            imageList = [imagesData];
          }
        }

        // Construct a temporary Product object from the JSON data
        scannedProduct = Product(
          name: decoded['name'] ?? '',
          sku: skuToCheck,
          category: decoded['category'] ?? '',
          quantity: int.tryParse(decoded['quantity'].toString()) ?? 0,
          costPrice: double.tryParse(decoded['cost']?.toString() ?? '0') ?? 0.0, // 'cost' in JSON -> 'costPrice' in model
          sellingPrice: double.tryParse(decoded['price']?.toString() ?? '0') ?? 0.0, // 'price' in JSON -> 'sellingPrice' in model
          supplier: decoded['supplier'],
          images: imageList,
        );
      }
    } catch (e) {
      // Not a valid JSON, assume it's just a plain SKU string
      skuToCheck = rawCode;
    }
    
    if (!mounted) return;

    final viewModel = Provider.of<StockViewModel>(context, listen: false);
    final languageViewModel = Provider.of<LanguageViewModel>(context, listen: false);

    // Validate Category if scannedProduct was parsed from JSON
    if (scannedProduct != null && scannedProduct.category.isNotEmpty) {
      if (!viewModel.categories.contains(scannedProduct.category)) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(languageViewModel.translate('category_not_allowed')),
              content: Text(languageViewModel.translate('category_not_found_msg').replaceAll('{category}', scannedProduct!.category)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (mounted) {
                      controller.start();
                      setState(() {
                        _isProcessing = false;
                      });
                    }
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    final Product? existingProduct = viewModel.findProductBySku(skuToCheck);

    if (existingProduct != null) {
      // Product found -> Go to details
       if (!mounted) return;
       await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: existingProduct),
        ),
      );
    } else {
      // Product not found -> Ask to create
      if (!mounted) return;
      _showCreateDialog(skuToCheck, scannedProduct);
      return; 
    }

    // Resume scanning when back from details
    if (mounted) {
      await controller.start();
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showCreateDialog(String sku, [Product? scannedProduct]) {
    final languageViewModel = Provider.of<LanguageViewModel>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(languageViewModel.translate('product_not_found')),
        content: Text("${languageViewModel.translate('no_product_sku')}: $sku\n${languageViewModel.translate('want_to_add')}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Resume camera on cancel
              controller.start(); 
              setState(() {
                _isProcessing = false;
              });
            },
            child: Text(languageViewModel.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddProductScreen(
                    product: scannedProduct ?? Product(
                      name: '',
                      sku: sku, // Pre-fill SKU
                      category: '',
                      quantity: 0,
                      costPrice: 0.0,
                      sellingPrice: 0.0,
                    ),
                  ),
                ),
              ).then((_) async {
                 if (mounted) {
                   // Resume camera after returning from Add Screen
                   await controller.start();
                   setState(() {
                     _isProcessing = false;
                   });
                 }
              });
            },
            child: Text(languageViewModel.translate('add_product')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if running on desktop where camera might not be available or just for easier testing
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final languageViewModel = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageViewModel.translate('scan_product')),
        backgroundColor: AppColors.bleuStock,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  default: // Handle auto or other states if any
                     return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                  default: 
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      "${languageViewModel.translate('camera_error')}: ${error.errorCode}",
                      style: const TextStyle(color: Colors.red),
                    ),
                    if (isDesktop)
                       const Padding(
                         padding: EdgeInsets.only(top: 20.0),
                         child: Text("Camera might not be supported on this platform."),
                       )
                  ],
                ),
              );
            },
          ),
          
          // Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.vertCroissance, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Instruction Text
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              languageViewModel.translate('align_barcode'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                backgroundColor: Colors.black45,
              ),
            ),
          ),
          
          // Desktop Simulator / Manual Input
          if (isDesktop)
            Positioned(
              top: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  // Simulate scanning a code
                  _showManualEntryDialog(languageViewModel);
                },
                child: Text(languageViewModel.translate('simulate_input')),
              ),
            ),
        ],
      ),
    );
  }

  void _showManualEntryDialog(LanguageViewModel languageViewModel) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(languageViewModel.translate('manual_sku_entry')),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(labelText: languageViewModel.translate('enter_sku')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(languageViewModel.translate('cancel'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (textController.text.isNotEmpty) {
                _processCode(textController.text);
              }
            },
            child: Text(languageViewModel.translate('search')),
          ),
        ],
      ),
    );
  }
}