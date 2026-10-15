import 'package:flutter/services.dart';

class HapticService {
  HapticService._();

  static HapticService? _instance;
  static HapticService get instance => _instance ??= HapticService._();

  bool enabled = true;

  void lightTap() {
    if (!enabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {
      // Ignored on unsupported platforms.
    }
  }

  void mediumImpact() {
    if (!enabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {
      // Ignored on unsupported platforms.
    }
  }

  void heavyImpact() {
    if (!enabled) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {
      // Ignored on unsupported platforms.
    }
  }

  void selectionClick() {
    if (!enabled) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {
      // Ignored on unsupported platforms.
    }
  }
}
