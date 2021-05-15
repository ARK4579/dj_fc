import 'package:path/path.dart' as p;

import 'package:dj_io/dj_io.dart';
import 'package:dj_fc/dj_fc.dart';

const String FLUTTER_SDK_LOCATION = 'D:\\src\\flutter';

void main() {
  var flutterSdkWidgetProcessor = FlutterSdkWidgetProcessor(
    sdkLocation: FLUTTER_SDK_LOCATION,
  );

  var rawWidgets = flutterSdkWidgetProcessor.process();

  var djNamesMap = <String, String>{
    'Widget': 'WidgetDj',
    'List<Widget>': 'List<WidgetDj>',
    'Widget?': 'WidgetDj?',
    'List<Widget>?': 'List<WidgetDj>?',
  };

  rawWidgets.forEach((rawWidget) {
    djNamesMap[rawWidget.name] = rawWidget.widgetDjName;
    djNamesMap['${rawWidget.name}?'] = '${rawWidget.widgetDjName}?';
    djNamesMap['List<${rawWidget.name}>'] = 'List<${rawWidget.widgetDjName}>';
    djNamesMap['List<${rawWidget.name}>?'] = 'List<${rawWidget.widgetDjName}>?';
  });

  var outputDir = p.join('..', 'dj', 'lib', 'main', 'djs');
  var baseDj = BaseDj(
    path: outputDir,
    node: DirectoryDj(
      name: 'widget_djs',
      nodes: [
        FileDj(
          name: 'dj_names_map',
          codeParts: [
            MapDj(
              name: 'djNamesMap',
              keyDataType: 'String',
              valueDataType: 'String',
              values: djNamesMap,
            ),
          ],
        ),
      ],
    ),
  );

  var baseDjIo = BaseDjIo(baseDjMap: baseDj.toJson());
  baseDjIo.write();
}
