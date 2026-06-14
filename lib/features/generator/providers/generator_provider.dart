import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// State for the QR generator.
class GeneratorState {
  final String text;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;
  final int errorCorrectionLevel;

  const GeneratorState({
    this.text = '',
    this.size = 200.0,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.errorCorrectionLevel = QrErrorCorrectLevel.M,
  });

  GeneratorState copyWith({
    String? text,
    double? size,
    Color? foregroundColor,
    Color? backgroundColor,
    int? errorCorrectionLevel,
  }) {
    return GeneratorState(
      text: text ?? this.text,
      size: size ?? this.size,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
    );
  }
}

class GeneratorNotifier extends Notifier<GeneratorState> {
  @override
  GeneratorState build() => const GeneratorState();

  void setText(String text) => state = state.copyWith(text: text);
  void setSize(double size) => state = state.copyWith(size: size);
  void setForegroundColor(Color color) =>
      state = state.copyWith(foregroundColor: color);
  void setBackgroundColor(Color color) =>
      state = state.copyWith(backgroundColor: color);
  void setErrorCorrection(int level) =>
      state = state.copyWith(errorCorrectionLevel: level);
}

final generatorProvider =
    NotifierProvider<GeneratorNotifier, GeneratorState>(GeneratorNotifier.new);
