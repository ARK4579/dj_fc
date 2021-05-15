import 'package:path/path.dart' as p;

import 'package:dj_io/dj_io.dart';
import 'package:dj_fc/dj_fc.dart';

const String FLUTTER_SDK_LOCATION = 'D:\\src\\flutter';

void main() {
  var flutterSdkWidgetProcessor = FlutterSdkWidgetProcessor(
    sdkLocation: FLUTTER_SDK_LOCATION,
  );

  var rawWidgets = flutterSdkWidgetProcessor.process();

  var djNamesMap = <String, String>{};

  rawWidgets.forEach((rawWidget) {
    djNamesMap[rawWidget.name] = rawWidget.widgetDjName;
  });

  var outputDir = p.join('..', 'dj_fj', 'lib', 'src');
  var baseDj = BaseDj(
    path: outputDir,
    node: DirectoryDj(
      name: 'widget_djs',
      nodes: [
        FileDj(
          name: 'widget_dj_types',
          codeParts: [
            EnumDj(
              name: 'WidgetDjTypes',
              values: djNamesMap.keys.toList(),
            ),
          ],
        ),
      ],
    ),
  );

  var baseDjIo = BaseDjIo(baseDjMap: baseDj.toJson());
  baseDjIo.write();
}
