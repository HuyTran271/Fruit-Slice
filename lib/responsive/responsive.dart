import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

enum DeviceType { mobile, tablet, desktop }

class ResponsiveConfig {
  final double topPadding;
  final double sidePadding;
  final double panelPadding;
  final double borderRadius;
  final double spacing;
  final double scoreFontSize;
  final double timeFontSize;
  final double comboFontSize;
  final double smallTextSize;
  final double heartSize;
  final double iconSize;
  final double settingsButtonSize;
  final double badgePadding;
  final double comboTop;

  const ResponsiveConfig({
    required this.topPadding,
    required this.sidePadding,
    required this.panelPadding,
    required this.borderRadius,
    required this.spacing,
    required this.scoreFontSize,
    required this.timeFontSize,
    required this.comboFontSize,
    required this.smallTextSize,
    required this.heartSize,
    required this.iconSize,
    required this.settingsButtonSize,
    required this.badgePadding,
    required this.comboTop,
  });
}

DeviceType getDeviceType(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final shortestSide = size.shortestSide;
  if (kIsWeb) {
    if (size.width > 1200) return DeviceType.desktop;
    if (size.width > 600) return DeviceType.tablet;
    return DeviceType.mobile;
  } else {
    return shortestSide > 600 ? DeviceType.tablet : DeviceType.mobile;
  }
}

ResponsiveConfig getResponsiveConfig(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final deviceType = getDeviceType(context);

  switch (deviceType) {
    case DeviceType.mobile:
      if (width < 360) {
        return const ResponsiveConfig(
          topPadding: 12,
          sidePadding: 8,
          panelPadding: 10,
          borderRadius: 14,
          spacing: 4,
          scoreFontSize: 18,
          timeFontSize: 14,
          comboFontSize: 24,
          smallTextSize: 10,
          heartSize: 16,
          iconSize: 18,
          settingsButtonSize: 36,
          badgePadding: 4,
          comboTop: 100,
        );
      } else {
        return const ResponsiveConfig(
          topPadding: 16,
          sidePadding: 10,
          panelPadding: 12,
          borderRadius: 16,
          spacing: 6,
          scoreFontSize: 22,
          timeFontSize: 16,
          comboFontSize: 28,
          smallTextSize: 12,
          heartSize: 18,
          iconSize: 20,
          settingsButtonSize: 40,
          badgePadding: 6,
          comboTop: 110,
        );
      }

    case DeviceType.tablet:
      return const ResponsiveConfig(
        topPadding: 20,
        sidePadding: 16,
        panelPadding: 14,
        borderRadius: 18,
        spacing: 8,
        scoreFontSize: 26,
        timeFontSize: 18,
        comboFontSize: 32,
        smallTextSize: 14,
        heartSize: 22,
        iconSize: 24,
        settingsButtonSize: 48,
        badgePadding: 8,
        comboTop: 120,
      );

    case DeviceType.desktop:
      return const ResponsiveConfig(
        topPadding: 24,
        sidePadding: 20,
        panelPadding: 16,
        borderRadius: 20,
        spacing: 10,
        scoreFontSize: 30,
        timeFontSize: 20,
        comboFontSize: 36,
        smallTextSize: 16,
        heartSize: 26,
        iconSize: 28,
        settingsButtonSize: 52,
        badgePadding: 10,
        comboTop: 130,
      );
  }
}
