import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// State for the scanner screen.
class ScannerState {
  final bool isTorchOn;
  final bool isPaused;

  const ScannerState({
    this.isTorchOn = false,
    this.isPaused = false,
  });

  ScannerState copyWith({bool? isTorchOn, bool? isPaused}) {
    return ScannerState(
      isTorchOn: isTorchOn ?? this.isTorchOn,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

/// Notifier that manages the MobileScannerController lifecycle and torch state.
class ScannerNotifier extends Notifier<ScannerState> {
  late final MobileScannerController controller;

  @override
  ScannerState build() {
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      autoStart: true,
      // No explicit formats list — defaults to all supported formats.
    );

    // Dispose the controller when the provider is disposed
    ref.onDispose(() => controller.dispose());

    return const ScannerState();
  }

  Future<void> toggleTorch() async {
    await controller.toggleTorch();
    state = state.copyWith(isTorchOn: !state.isTorchOn);
  }

  Future<void> pause() async {
    try {
      await controller.stop();
    } catch (_) {}
    state = state.copyWith(isPaused: true);
  }

  Future<void> resume() async {
    try {
      await controller.start();
    } catch (_) {}
    state = state.copyWith(isPaused: false);
  }

  /// Analyzes an image from the gallery.
  /// Returns the [BarcodeCapture] if any barcode was found, or null.
  Future<BarcodeCapture?> analyzeImage(String imagePath) async {
    return await controller.analyzeImage(imagePath);
  }
}

final scannerProvider =
    NotifierProvider<ScannerNotifier, ScannerState>(ScannerNotifier.new);
