import 'package:path/path.dart' as p;

import 'package:dj_io/dj_io.dart';
import 'package:dj_fc/dj_fc.dart';

const String FLUTTER_SDK_LOCATION = 'D:\\src\\flutter';

void main() {
  var flutterSdkWidgetProcessor = FlutterSdkWidgetProcessor(
    sdkLocation: FLUTTER_SDK_LOCATION,
  );

  var rawWidgets = flutterSdkWidgetProcessor.process();

  var djNamesMap = getDjNamesMap(rawWidgets);

  var widgetFileDjs = <FileDj>[];

  rawWidgets.forEach((rawWidget) {
    var widgetFileDj = rawWidget.toWidgetDjFileDj(djNamesMap);
    if (widgetFileDj != null) {
      widgetFileDjs.add(widgetFileDj);
    } else {
      print('No FileDj for ${rawWidget.name} @ ${rawWidget.originFilePath}');
    }
  });

  var exportFileDj = FileDj(
    name: 'auto_widget_djs',
    codeParts: widgetFileDjs.map((e) => ExportDj(exportStr: e.name)).toList(),
  );

  widgetFileDjs.add(exportFileDj);

  var outputDir = p.join('..', 'dj_fj', 'lib', 'src', 'widget_djs');
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
