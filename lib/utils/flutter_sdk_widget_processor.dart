import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:dj_fc/dj_fc.dart';

class FlutterSdkWidgetProcessor {
  final String sdkLocation;

  FlutterSdkWidgetProcessor({
    required this.sdkLocation,
  });

  List<RawWidgetDj> _processWidgetDirectory(directory) {
    var flutterWidgetsDirectory = Directory(directory);

    var flutterWidgetsDirectoryItems = flutterWidgetsDirectory
        .listSync(recursive: true, followLinks: false)
        .toList();

    var directoryRawWidgets = <RawWidgetDj>[];

    flutterWidgetsDirectoryItems.forEach((item) {
      var itemPath = item.uri.toFilePath();
      if (itemPath.endsWith('.dart')) {
        if (item.toString().startsWith('File')) {
          var rawWidgets = WidgetFileProcessor(file: item).process();
          directoryRawWidgets += rawWidgets;
        }
      }
    });

    return directoryRawWidgets;
  }

  List<RawWidgetDj> process() {
    var flutterWidgetLocation = p.join(
      sdkLocation,
      'packages',
      'flutter',
      'lib',
      'src',
      'widgets',
    );

    var flutterRawWidgets = _processWidgetDirectory(flutterWidgetLocation);

    print('Got ${flutterRawWidgets.length} Flutter Raw Widgets');

    var flutterRenderingWidgetLocation = p.join(
      sdkLocation,
      'packages',
      'flutter',
      'lib',
      'src',
      'rendering',
    );

    var flutterRenderingRawWidgets =
        _processWidgetDirectory(flutterRenderingWidgetLocation);

    print(
        'Got ${flutterRenderingRawWidgets.length} Flutter Rendering Raw Widgets');

    var allRawWidgets = flutterRawWidgets + flutterRenderingRawWidgets;

    return allRawWidgets;
  }
}
