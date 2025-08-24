import 'dart:async';
import 'dart:math';
import 'package:fl_clash/common/color.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/activate_box.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.qrCode],
    returnImage: false,
  );

  StreamSubscription<Object?>? _subscription;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startScanner();
  }

  Future<void> _startScanner() async {
    _subscription = controller.barcodes.listen(_handleBarcode);
    await controller.start();
    setState(() => _isScanning = true);
  }

  Future<void> _stopScanner() async {
    await _subscription?.cancel();
    _subscription = null;
    await controller.stop();
    setState(() => _isScanning = false);
  }

  void _handleBarcode(BarcodeCapture barcodeCapture) {
    if (!_isScanning) return;
    
    final barcode = barcodeCapture.barcodes.firstOrNull;
    if (barcode?.type == BarcodeType.url && barcode?.rawValue != null) {
      _stopScanner();
      Navigator.pop<String>(context, barcode?.rawValue);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _stopScanner();
        return;
      case AppLifecycleState.resumed:
        _startScanner();
      case AppLifecycleState.inactive:
        _stopScanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    double sideLength = min(400, MediaQuery.of(context).size.width * 0.67);
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(Offset.zero),
      width: sideLength,
      height: sideLength,
    );
    
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: MobileScanner(
              controller: controller,
              scanWindow: scanWindow,
            ),
          ),
          // 传入主题颜色作为扫描框边框色
          CustomPaint(
            painter: ScannerOverlay(
              scanWindow: scanWindow,
              borderColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: IconButton(
              style: ButtonStyle(
                iconSize: const WidgetStatePropertyAll(32),
                foregroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              onPressed: () {
                _stopScanner();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close),
            ),
            actions: [
              ValueListenableBuilder<MobileScannerState>(
                valueListenable: controller,
                builder: (context, state, _) {
                  late Widget icon;
                  late Color backgroundColor;
                  
                  switch (state.torchState) {
                    case TorchState.on:
                      icon = const Icon(Icons.flash_on);
                      backgroundColor = Colors.orange;
                    case TorchState.auto:
                      icon = const Icon(Icons.flash_auto);
                      backgroundColor = Colors.orange;
                    case TorchState.off:
                    case TorchState.unavailable:
                      icon = const Icon(Icons.flash_off);
                      backgroundColor = state.torchState == TorchState.unavailable
                          ? Colors.transparent
                          : Colors.black12;
                  }
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: ActivateBox(
                      active: state.torchState != TorchState.unavailable,
                      child: IconButton(
                        icon: icon,
                        style: ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.primary,
                          ),
                          backgroundColor: WidgetStatePropertyAll(backgroundColor),
                        ),
                        onPressed: () => controller.toggleTorch(),
                      ),
                    ),
                  );
                },
              )
            ],
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 32),
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.primary,
                  ),
                  backgroundColor: const WidgetStatePropertyAll(Colors.grey),
                  padding: const WidgetStatePropertyAll(EdgeInsets.all(16)),
                  iconSize: const WidgetStatePropertyAll(32.0),
                ),
                onPressed: globalState.appController.addProfileFormQrCode,
                icon: const Icon(Icons.photo_camera_back),
              ),
              const SizedBox(height: 16),
              if (!_isScanning)
                ElevatedButton(
                  onPressed: _startScanner,
                  child: const Text('重新扫描'),
                ),
            ],
	   ),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _stopScanner();
    await controller.dispose();
    super.dispose();
  }
}

class ScannerOverlay extends CustomPainter {
  // 新增borderColor参数，用于接收主题颜色
  const ScannerOverlay({
    required this.scanWindow,
    this.borderRadius = 12.0,
    required this.borderColor,
  });

  final Rect scanWindow;
  final double borderRadius;
  final Color borderColor; // 声明边框颜色变量

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          scanWindow,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    // 使用传入的borderColor作为边框颜色
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final borderRect = RRect.fromRectAndCorners(
      scanWindow,
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(ScannerOverlay oldDelegate) {
    return scanWindow != oldDelegate.scanWindow ||
        borderRadius != oldDelegate.borderRadius ||
        borderColor != oldDelegate.borderColor; // 新增颜色变化的重绘判断
  }
}
