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
    var widgetFolders = [
      'animation',
      'cupertino',
      'foundation',
      'gestures',
      'material',
      'painting',
      'physics',
      'rendering',
      'scheduler',
      'semantics',
      'services',
      'widgets',
    ];

    var baseFolder = p.join(
      sdkLocation,
      'packages',
      'flutter',
      'lib',
      'src',
    );

    // For Extracting Dart Widgets!
    // var widgetFolders = [
    //   'core',
    // ];
    // var baseFolder = p.join(
    //   sdkLocation,
    //   'bin',
    //   'cache',
    //   'pkg',
    //   'sky_engine',
    //   'lib',
    // );

    var allRawWidgets = <RawWidgetDj>[];

    widgetFolders.forEach((widgetFolder) {
      var flutterWidgetLocation = p.join(
        baseFolder,
        widgetFolder,
      );

      var folderRawWidgets = _processWidgetDirectory(flutterWidgetLocation);

      print(
        'Got ${folderRawWidgets.length} Raw Widgets from $widgetFolder widget folder',
      );

      allRawWidgets += folderRawWidgets;
    });

    print(
      'Got a Total of ${allRawWidgets.length} Raw Widgets from $baseFolder folder',
    );

    return allRawWidgets;
  }
}
