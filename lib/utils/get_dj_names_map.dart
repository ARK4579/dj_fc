import 'package:dj_fc/dj_fc.dart';

const String FLUTTER_SDK_LOCATION = 'D:\\src\\flutter';

Map<String, String> getDjNamesMap(List<RawWidgetDj> rawWidgets) {
  var flutterSdkWidgetProcessor = FlutterSdkWidgetProcessor(
    sdkLocation: FLUTTER_SDK_LOCATION,
  );

  var rawWidgets = flutterSdkWidgetProcessor.process();

  var djNamesMap = <String, String>{};

  rawWidgets.forEach((rawWidget) {
    djNamesMap[rawWidget.name] = rawWidget.widgetDjName;
    djNamesMap['${rawWidget.name}?'] = '${rawWidget.widgetDjName}?';
    djNamesMap['List<${rawWidget.name}>'] = 'List<${rawWidget.widgetDjName}>';
    djNamesMap['List<${rawWidget.name}>?'] = 'List<${rawWidget.widgetDjName}>?';
  });

  return djNamesMap;
}
