import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';

class UniversalScannerDialog extends StatefulWidget {
  final String title;
  final ValueChanged<String> onCodeScanned;

  const UniversalScannerDialog({
    super.key,
    this.title = 'Scan QR Code or Barcode',
    required this.onCodeScanned,
  });

  static Future<String?> show(BuildContext context, {String title = 'Scan QR / Barcode'}) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => UniversalScannerDialog(
        title: title,
        onCodeScanned: (code) {
          Navigator.pop(ctx, code);
        },
      ),
    );
  }

  @override
  State<UniversalScannerDialog> createState() => _UniversalScannerDialogState();
}

class _UniversalScannerDialogState extends State<UniversalScannerDialog> {
  final _manualController = TextEditingController();
  final _focusNode = FocusNode();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _manualController.dispose();
    _focusNode.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleCode(String code) {
    if (_hasScanned) return;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    _hasScanned = true;
    widget.onCodeScanned(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Camera Preview Box
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null) {
                              _handleCode(barcode.rawValue!);
                              break;
                            }
                          }
                        },
                      ),
                      // Overlay guide box
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primaryLight, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // Controls (Torch / Switch camera)
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.flash_on, color: Colors.white, size: 20),
                                onPressed: () => _scannerController.toggleTorch(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 20),
                                onPressed: () => _scannerController.switchCamera(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Hardware USB Barcode Scanner & Manual input field
              TextField(
                controller: _manualController,
                focusNode: _focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'USB Scanner / Manual Code Entry',
                  hintText: 'Ready for hardware scanner or type code...',
                  prefixIcon: const Icon(Icons.keyboard_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _handleCode(_manualController.text),
                  ),
                ),
                onSubmitted: _handleCode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
