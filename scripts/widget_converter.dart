import 'package:path/path.dart' as p;
import 'package:dj_fc/dj_fc.dart';

import 'utils/utils.dart';

const String FLUTTER_SDK_LOCATION =
    'C:\\Programs\\flutter\\flutter_windows\\flutter';

void main() {
  var flutterSdkWidgetProcessor = FlutterSdkWidgetProcessor(
    sdkLocation: FLUTTER_SDK_LOCATION,
  );

  var rawWidgets = flutterSdkWidgetProcessor.process();

  var djNamesMap = getDjNamesMap(rawWidgets);

  var outputDir = p.join('..', 'dj_fj', 'lib', 'src', 'widget_djs');

  writeRawWidgets(rawWidgets, djNamesMap, outputDir, 'auto');
}
