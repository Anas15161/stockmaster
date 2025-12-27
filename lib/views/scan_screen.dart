import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  // MobileScannerController handles the camera.
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

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

  Future<void> _processCode(String sku) async {
    setState(() {
      _isProcessing = true;
    });

    // Pause camera to stop scanning while we process
    // controller.stop(); // Optional: can just ignore new scans via _isProcessing flag
    
    final viewModel = Provider.of<StockViewModel>(context, listen: false);
    final Product? product = viewModel.findProductBySku(sku);

    if (product != null) {
      // Product found -> Go to details
       if (!mounted) return;
       await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );
    } else {
      // Product not found -> Ask to create
      if (!mounted) return;
      _showCreateDialog(sku);
      return; // Don't reset processing yet, dialog is open
    }

    // Resume scanning when back
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showCreateDialog(String sku) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Product Not Found"),
        content: Text("No product found with SKU: $sku\nDo you want to add it?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddProductScreen(
                    product: Product(
                      name: '',
                      sku: sku, // Pre-fill SKU
                      category: '',
                      quantity: 0,
                      costPrice: 0.0,
                      sellingPrice: 0.0,
                    ),
                  ),
                ),
              ).then((_) {
                 if (mounted) {
                   setState(() {
                     _isProcessing = false;
                   });
                 }
              });
            },
            child: const Text("Add Product"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if running on desktop where camera might not be available or just for easier testing
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Product"),
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
                      "Camera Error: ${error.errorCode}",
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
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              "Align barcode within the frame",
              textAlign: TextAlign.center,
              style: TextStyle(
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
                  _showManualEntryDialog();
                },
                child: const Text("Simulate / Manual Input"),
              ),
            ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Manual SKU Entry"),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: "Enter SKU"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (textController.text.isNotEmpty) {
                _processCode(textController.text);
              }
            },
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }
}
