import 'package:path/path.dart' as p;

import 'package:dj_io/dj_io.dart';
import 'package:dj_fc/dj_fc.dart';

const String FLUTTER_SDK_LOCATION = 'D:\\src\\flutter';

void main() {
  var flutterSdkWidgetProcessor = FlutterSdkWidgetProcessor(
    sdkLocation: FLUTTER_SDK_LOCATION,
  );

  var rawWidgets = flutterSdkWidgetProcessor.process();

  var widgetFileDjs = <FileDj>[];

  rawWidgets.forEach((rawWidget) {
    var widgetFileDj = rawWidget.toWidgetDjFileDj();
    if (widgetFileDj != null) {
      widgetFileDjs.add(widgetFileDj);
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
