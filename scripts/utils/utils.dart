import 'package:dj_io/dj_io.dart';
import 'package:dj_fc/dj_fc.dart';

void writeRawWidgets(
  List<RawWidgetDj> rawWidgets,
  Map<String, String> djNamesMap,
  String outputParentDir,
  String outputDirName,
) {
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
    name: outputDirName,
    codeParts: widgetFileDjs.map((e) => ExportDj(exportStr: e.name)).toList(),
  );

  widgetFileDjs.add(exportFileDj);

  var baseDj = BaseDj(
    path: outputParentDir,
    node: DirectoryDj(
      name: outputDirName,
      nodes: widgetFileDjs,
    ),
  );

  var baseDjIo = BaseDjIo(baseDjMap: baseDj.toJson());
  baseDjIo.write();
}
