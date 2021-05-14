import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:dj_io/dj_io.dart';
import 'package:dj_fc/dj_fc.dart';

const String FLUTTER_SDK_LOCATION = 'D:\\src\\flutter';

void main() {
  var flutterWidgetLocation = p.join(
    FLUTTER_SDK_LOCATION,
    'packages',
    'flutter',
    'lib',
    'src',
    'widgets',
  );

  var flutterWidgetsDirectory = Directory(flutterWidgetLocation);

  print('directory: ${flutterWidgetsDirectory.absolute.toString()}');

  var flutterWidgetsDirectoryItems = flutterWidgetsDirectory
      .listSync(recursive: true, followLinks: false)
      .toList();

  print(('Got ${flutterWidgetsDirectoryItems.length} items'));

  var widgetFileDjs = <FileDj>[];

  flutterWidgetsDirectoryItems.forEach((item) {
    var itemPath = item.uri.toFilePath();
    if (itemPath.endsWith('.dart')) {
      if (item.toString().startsWith('File')) {
        var rawWidgets = WidgetFileProcessor(file: item).process();
        print('>>>>>>>>>>>>>>>>>$itemPath');
        rawWidgets.forEach((rawWidget) {
          print(rawWidget);
          var widgetFileDj = rawWidget.toWidgetDjFileDj();
          if (widgetFileDj != null) {
            widgetFileDjs.add(widgetFileDj);
          }
        });
        print('');
      }
    }
  });

  var outputDir = p.join('..', 'dj', 'lib', 'main', 'djs', 'widget_djs');
  var baseDj = BaseDj(
    path: outputDir,
    node: DirectoryDj(
      name: 'auto',
      nodes: widgetFileDjs,
    ),
  );

  var baseDjIo = BaseDjIo(baseDjMap: baseDj.toJson());
  baseDjIo.write();
}
