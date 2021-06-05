import 'package:dj_fc/dj_fc.dart';

Map<String, String> getDjNamesMap(
  List<RawWidgetDj> rawWidgets, {
  bool includeVariants = true,
}) {
  var djNamesMap = <String, String>{};

  rawWidgets.forEach((rawWidget) {
    djNamesMap[rawWidget.name] = rawWidget.widgetDjName;
    if (includeVariants) {
      djNamesMap['${rawWidget.name}?'] = '${rawWidget.widgetDjName}?';
      djNamesMap['List<${rawWidget.name}>'] = 'List<${rawWidget.widgetDjName}>';
      djNamesMap['List<${rawWidget.name}>?'] =
          'List<${rawWidget.widgetDjName}>?';
    }
  });

  djNamesMap['Widget'] = 'BaseWidgetDj';
  djNamesMap['Widget?'] = 'BaseWidgetDj?';
  djNamesMap['List<Widget>'] = 'List<BaseWidgetDj>';
  djNamesMap['List<Widget>?'] = 'List<BaseWidgetDj>?';

  return djNamesMap;
}
