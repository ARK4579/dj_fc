import 'dart:io';

import 'package:args/args.dart';

import 'package:dj_fc/dj_fc.dart';

import 'utils/utils.dart';

const String PATH_ARGUMENT_NAME = 'path';
const String FLUTTER_SDK_LOCATION =
    'C:\\Programs\\flutter\\flutter_windows\\flutter';
const DJS_DIRECTORY_NAME = 'djs';

List<String> getAllLines(String path) {
  var allLines = <String>[];

  var directory = Directory(path);

  directory.listSync(recursive: false).forEach((f) {
    print(f.path);
    if (f is File) {
      allLines += f.readAsLinesSync();
    } else if (f is Directory) {
      if (!f.path.endsWith('\\$DJS_DIRECTORY_NAME')) {
        print('Goging down in ${f.path}');
        allLines += getAllLines(f.absolute.path);
      }
    }
  });

  return allLines;
}

void main(List<String> arguments) {
  final parser = ArgParser()..addOption(PATH_ARGUMENT_NAME, abbr: 'p');
  var argResults = parser.parse(arguments);

  String? path = argResults[PATH_ARGUMENT_NAME];

  if (path != null) {
    print(path);

    var directory = Directory(path);
    if (directory.existsSync()) {
      var allLines = getAllLines(path);

      allLines = removeComments(allLines);

      var allLinesString = allLines.join('\n');

      var flutterSdkWidgetProcessor = FlutterSdkWidgetProcessor(
        sdkLocation: FLUTTER_SDK_LOCATION,
      );

      var rawWidgets = flutterSdkWidgetProcessor.process();

      var djNamesMap = getDjNamesMap(rawWidgets, includeVariants: false);

      var allDjNames = djNamesMap.values.toList();

      var requiredDjNames = <String>[];

      allDjNames.forEach((djName) {
        if (allLinesString.contains(djName)) {
          requiredDjNames.add(djName);
        }
      });

      print('requiredDjNames $requiredDjNames');

      rawWidgets.removeWhere(
          (rawWidget) => !requiredDjNames.contains(rawWidget.widgetDjName));

      writeRawWidgets(rawWidgets, djNamesMap, path, DJS_DIRECTORY_NAME);
    } else {
      print('$path not found! Please make sure correct path is provided');
    }
  } else {
    print('Please provide path Argument by -p or --path');
  }
}
