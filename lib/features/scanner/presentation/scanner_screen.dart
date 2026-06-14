import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:uuid/uuid.dart';
import '../domain/scan_result_model.dart';
import '../providers/scanner_provider.dart';
import 'widgets/scan_overlay.dart';
import 'widgets/torch_button.dart';
import 'widgets/result_sheet.dart';
import '../../../shared/utils/scan_action_handler.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/history/providers/history_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

const _uuid = Uuid();

/// Distinguishes what the user chose when dismissing the gallery result sheet.
enum _GalleryAction { useCamera, pickAnother }

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  bool _sheetOpen = false;
  bool _permissionDenied = false;
  bool _isProcessing = false;
  bool _isRecoveringCamera = false;

  // Manual dedup: ignore same QR scanned within this window
  static const _dedupWindow = Duration(seconds: 3);
  String? _lastScannedRaw;
  DateTime? _lastScannedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermission());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Skip lifecycle-driven camera control while gallery processing is active
    if (_isProcessing) return;
    if (state == AppLifecycleState.paused) {
      if (!_sheetOpen) {
        ref.read(scannerProvider.notifier).pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_sheetOpen) {
        ref.read(scannerProvider.notifier).resume();
      }
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return;

    if (status.isDenied) {
      // Show rationale first
      final shouldRequest = await _showPermissionRationale();
      if (!shouldRequest) {
        setState(() => _permissionDenied = true);
        return;
      }
      final result = await Permission.camera.request();
      if (!result.isGranted) setState(() => _permissionDenied = true);
    } else if (status.isPermanentlyDenied) {
      setState(() => _permissionDenied = true);
    }
  }

  Future<bool> _showPermissionRationale() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Camera Permission'),
        content: const Text(
          'ScanVault needs camera access to scan QR codes and barcodes.\n\n'
          'No images are stored or transmitted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Attempts an automatic camera restart after a transient hardware error.
  /// Must NOT be called synchronously during a build — use addPostFrameCallback.
  Future<void> _onCameraError() async {
    // Guard against concurrent recovery attempts
    if (!mounted || _isRecoveringCamera) return;
    _isRecoveringCamera = true;

    // Give the camera hardware time to reset
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) {
      _isRecoveringCamera = false;
      return;
    }

    try {
      await ref.read(scannerProvider.notifier).resume();
    } catch (_) {
      // If resume fails, recreate the entire controller
      if (mounted) ref.invalidate(scannerProvider);
    }

    _isRecoveringCamera = false;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_sheetOpen || _isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final raw = barcode!.rawValue!;

    // Manual dedup — replaces DetectionSpeed.noDuplicates
    final now = DateTime.now();
    if (raw == _lastScannedRaw &&
        _lastScannedAt != null &&
        now.difference(_lastScannedAt!) < _dedupWindow) {
      return;
    }
    _lastScannedRaw = raw;
    _lastScannedAt = now;

    _isProcessing = true;
    final type = detectScanType(raw);
    final result = ScanResultModel(
      id: _uuid.v4(),
      rawContent: raw,
      type: type,
      scannedAt: DateTime.now(),
    );

    // Haptic feedback
    HapticFeedback.mediumImpact();
    final settings = ref.read(appSettingsProvider);
    if (settings.vibrationEnabled) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 80);
      }
    }

    // Auto-save to history
    if (settings.saveHistory) {
      await ref.read(historyProvider.notifier).addScan(result);
    }

    // Pause scanner and show result sheet
    await ref.read(scannerProvider.notifier).pause();
    setState(() {
      _sheetOpen = true;
    });

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => ResultSheet(
        result: result,
        onScanNext: () => Navigator.of(ctx).pop(),
      ),
    );

    // Resume after user taps Scan Next
    if (mounted) {
      setState(() {
        _sheetOpen = false;
      });
      // Reset dedup so the same code can be scanned again immediately
      _lastScannedRaw = null;
      _lastScannedAt = null;
      await ref.read(scannerProvider.notifier).resume();
    }
    _isProcessing = false;
  }

  Future<void> _pickFromGallery() async {
    // Mark as processing so lifecycle events don't interfere
    _isProcessing = true;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      // User cancelled — clear flag and let lifecycle resume the scanner
      _isProcessing = false;
      return;
    }

    // Pause after image is selected (not before — avoids double-stop via lifecycle)
    await ref.read(scannerProvider.notifier).pause();

    // analyzeImage returns the BarcodeCapture directly (not via onDetect)
    final capture =
        await ref.read(scannerProvider.notifier).analyzeImage(image.path);

    if (capture == null || capture.barcodes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No QR code or barcode found in this image'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      await ref.read(scannerProvider.notifier).resume();
      _isProcessing = false;
      return;
    }

    // Process the detected barcode (scanner is already paused, _isProcessing stays true)
    await _handleGalleryCapture(capture);
  }

  Future<void> _handleGalleryCapture(BarcodeCapture capture) async {
    // Note: _isProcessing is already true and scanner already paused by caller
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) {
      await ref.read(scannerProvider.notifier).resume();
      _isProcessing = false;
      return;
    }

    final raw = barcode!.rawValue!;
    final type = detectScanType(raw);
    final result = ScanResultModel(
      id: _uuid.v4(),
      rawContent: raw,
      type: type,
      scannedAt: DateTime.now(),
    );

    // Haptic feedback
    HapticFeedback.mediumImpact();
    final settings = ref.read(appSettingsProvider);
    if (settings.vibrationEnabled) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 80);
      }
    }

    // Auto-save to history
    if (settings.saveHistory) {
      await ref.read(historyProvider.notifier).addScan(result);
    }

    setState(() {
      _sheetOpen = true;
    });

    if (!mounted) return;
    final action = await showModalBottomSheet<_GalleryAction>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => ResultSheet(
        result: result,
        // "Use Camera" — dismiss sheet and resume live scanner
        onScanNext: () => Navigator.of(ctx).pop(_GalleryAction.useCamera),
        // "Pick Another" — dismiss sheet and open gallery again
        onScanFromGallery: () =>
            Navigator.of(ctx).pop(_GalleryAction.pickAnother),
      ),
    );

    if (!mounted) {
      _isProcessing = false;
      return;
    }

    setState(() => _sheetOpen = false);

    if (action == _GalleryAction.pickAnother) {
      // Stay paused, re-open gallery picker
      _isProcessing = false;
      _pickFromGallery();
    } else {
      // Default: resume live camera
      await ref.read(scannerProvider.notifier).resume();
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);
    final notifier = ref.read(scannerProvider.notifier);

    if (_permissionDenied) {
      return _PermissionDeniedScreen(onRetry: _checkPermission);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          MobileScanner(
            controller: notifier.controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              // errorBuilder runs during build — defer recovery to post-frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onCameraError();
              });
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Restarting camera…',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Animated scan overlay
          const ScanOverlay(),

          // Top bar with title
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_scanner,
                            color: AppColors.brandTeal, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'ScanVault',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scan instruction text
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Point camera at a QR code or barcode',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Torch button
                    TorchButton(
                      isOn: scannerState.isTorchOn,
                      onToggle: () => notifier.toggleTorch(),
                    ),

                    // Gallery button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                      child: IconButton(
                        onPressed: _pickFromGallery,
                        icon: const Icon(
                          Icons.photo_library_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        tooltip: 'Scan from gallery',
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when camera permission is permanently denied.
class _PermissionDeniedScreen extends StatelessWidget {
  const _PermissionDeniedScreen({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_rounded, size: 72, color: cs.error),
              const SizedBox(height: 24),
              Text(
                'Camera Access Required',
                style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'ScanVault needs camera permission to scan QR codes and barcodes.\n\n'
                'Please enable it in your device Settings → Apps → ScanVault → Permissions.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open Settings'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
