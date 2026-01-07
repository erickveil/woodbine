import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart' as window_size;
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get the app version
  final packageInfo = await PackageInfo.fromPlatform();
  final version = packageInfo.version;

  // Fixed pager-like window size for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    const double width = 420;
    const double minHeight = 840;

    window_size.setWindowTitle('Woodbine v$version');
    final info = await window_size.getWindowInfo();
    if (info.screen != null) {
      final screenFrame = info.screen!.visibleFrame;
      final left = screenFrame.left + (screenFrame.width - width) / 2;
      final top = screenFrame.top + (screenFrame.height - minHeight) / 2;
      window_size.setWindowFrame(ui.Rect.fromLTWH(left, top, width, minHeight));
      window_size.setWindowMinSize(const ui.Size(width, minHeight));
      window_size.setWindowMaxSize(ui.Size(width, screenFrame.height));
    } else {
      // If screen info isn't available, still set min/max size so window is fixed.
      window_size.setWindowMinSize(const ui.Size(width, minHeight));
      window_size.setWindowMaxSize(const ui.Size(width, 2000));
    }
  }

  runApp(const DiceRollerApp());
}
