import 'dart:io';

import 'package:path/path.dart' as p;

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

  flutterWidgetsDirectoryItems.forEach((item) {
    var itemPath = item.uri.toFilePath();
    if (itemPath.endsWith('.dart')) {
      if (item.toString().startsWith('File')) {
        var widgetParameters = WidgetFileProcessor(file: item).process();
        print('>>>>>>>>>>>>>>>>>$itemPath');
        widgetParameters.forEach((widgetParameter) {
          print(widgetParameter);
        });
        print('');
      }
    }
  });
}
