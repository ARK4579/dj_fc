import 'dart:io';

import '../models/models.dart';
import '../utils/utils.dart';

//... If this value is set this means that we will be generating dj version of
//... only this widget
// const String? KEEP_ONLY_WIDGET = 'Text';
const String? KEEP_ONLY_WIDGET = null;

int fileDebugLvl = KEEP_ONLY_WIDGET == null ? 0 : 6;

class WidgetFileProcessor {
  final FileSystemEntity file;

  WidgetFileProcessor({
    required this.file,
  });

  static String currentFileName = '';
  static String currentConstructorName = '';

  String? _isConstructorLine(String line) {
    if (CommentLineChecker(line: line).check()) {
      // Not a constructor line because it's a comment line
      return null;
    }
    var regEx1Str = 'class .* {';
    var regEx1 = RegExp(regEx1Str);

    if (regEx1.hasMatch(line)) {
      var match = regEx1.firstMatch(line);
      if (match != null) {
        var matchString = line;
        matchString = matchString.split('abstract ').last;
        if (matchString.startsWith('class')) {
          var className = matchString
              .split('class ')
              .last
              .split(' {')
              .first
              .split(' extends ')
              .first
              .split(' with ')
              .first
              .split(' implements ')
              .first
              .split('<')
              .first;
          if (className == '{' || className.contains(' ')) {
            print(
                "'$className' => '${file.absolute.toString()}' @ $matchString\t\n'$line'");
          }
          if (className.startsWith('_')) return null;
          return className;
        }
      }
    }
  }

  List<RawWidgetDj> process() {
    var rawWidgetDjs = <RawWidgetDj>[];

    var itemPath = file.uri.toFilePath();

    currentFileName = itemPath;

    var fileHandler = File(itemPath);

    var fileLines = fileHandler.readAsLinesSync().toList();

    var parameterLines = <String>[];

    // 0 => Not Found Yet
    // 1 => Constructor comments running
    // 2 => Constructor
    // 3 => After Constructor
    var constructorFound = 0;
    String? constructorName;
    var constructorLess = false;
    var initialIsOptional = false;
    fileLines.forEach((line) {
      var parsedLine = WhiteSpaceRemover(line: line).removeFromStart();
      var _constructorName = _isConstructorLine(line);
      if (constructorFound == 0 && _constructorName != null) {
        initialIsOptional = false;
        constructorName = _constructorName;
        constructorFound = 1;
        constructorLess = false;
        currentConstructorName = constructorName!;

        if (KEEP_ONLY_WIDGET != null && constructorName != KEEP_ONLY_WIDGET) {
          constructorFound = 0;
        }
      } else if (constructorFound == 1 && !parsedLine.startsWith('///')) {
        constructorFound = 2;
        constructorLess = !line.contains(constructorName!) ||
            line.contains('super') ||
            (line.endsWith('{') && line.contains(')'));

        if (line.endsWith('({')) {
          initialIsOptional = true;
        }

        // Check if this is a single line constructor
        if (line.contains(constructorName! + '(') &&
            line.contains(')') &&
            !line.contains('()') &&
            !line.contains('=')) {
          if (fileDebugLvl > 5) {
            print("Parsing single line constructor: '$line'");
          }

          var singleConstructorLine = line;
          if (singleConstructorLine.contains(':')) {
            singleConstructorLine = singleConstructorLine.split(':').first;
          }

          var regExStr = 'Map<.*>';
          var regEx = RegExp(regExStr);

          if (regEx.hasMatch(singleConstructorLine)) {
            if (fileDebugLvl > 5) {
              print('Map Warning!');
            }
            var match = regEx.firstMatch(singleConstructorLine);
            if (match != null) {
              var match_0 = match.group(0);
              if (match_0 != null) {
                if (fileDebugLvl > 5) {
                  print("Map is: '$match_0'");
                }
                singleConstructorLine =
                    singleConstructorLine.replaceAll(match_0, 'dynamic');
              }
            }
          }

          // get all the parameters
          var paramsLinePart = singleConstructorLine
              .split(constructorName! + '(')
              .last
              .split(')')
              .first;
          paramsLinePart =
              paramsLinePart.replaceAll('{', '').replaceAll('}', '');

          if (fileDebugLvl > 5) {
            print('parsedLine $paramsLinePart');
          }

          var params = paramsLinePart
              .split(',')
              .map((e) => WhiteSpaceRemover(line: e).remove() + ',')
              .toList();

          // parse them
          var parsedParameters = processParameterLines(
            params,
            intialIsOptional: true,
          );

          if (fileDebugLvl > 5) {
            print('params: $params; parsed: ${parsedParameters.length}');
          }

          // get widget
          var rawWidgetDj = RawWidgetDj(
            parameters: parsedParameters,
            name: constructorName!,
            originFilePath: itemPath,
          );

          rawWidgetDjs.add(rawWidgetDj);

          // and let the world know that we have got constructor
          constructorFound = 0;

          parameterLines = [];
          constructorName = null;
        }
      } else if (constructorFound == 2 &&
          (line.isEmpty ||
              (line.endsWith('{') && line.contains(')')) ||
              (line.contains('=') && line.contains(')')) ||
              (line.contains('{') && line.endsWith('})')))) {
        constructorFound = 0;

        rawWidgetDjs.add(
          processWidgetParams(
            constructorName!,
            parameterLines,
            itemPath,
            initialIsOptional: initialIsOptional,
          ),
        );

        parameterLines = [];
        constructorName = null;
      }

      if (constructorFound == 2 && !constructorLess) {
        if (fileDebugLvl > 5 &&
            KEEP_ONLY_WIDGET != null &&
            KEEP_ONLY_WIDGET == constructorName) {
          print("line: '$line'");
        }
        parameterLines.add(line);
      }
    });

    return rawWidgetDjs;
  }

  RawWidgetDj processWidgetParams(
    String name,
    List<String> lines,
    String filePath, {
    int debugLvl = 0,
    bool initialIsOptional = false,
  }) {
    var parameterLines = <String>[];

    var gotAllParameters = false;
    lines.forEach((line) {
      if (!line.contains('$name(') &&
          !gotAllParameters &&
          line.isNotEmpty &&
          !CommentLineChecker(line: line).check()) {
        if ((line.contains(')') && line.contains(':')) ||
            line.contains(');') ||
            (line.contains(':') && line.contains('assert'))) {
          gotAllParameters = true;
        }
        if (!gotAllParameters) {
          parameterLines.add(line);
        }
      }
    });

    var parameters = processParameterLines(
      parameterLines,
      intialIsOptional: initialIsOptional,
    );

    var rawWidgetDj = RawWidgetDj(
      parameters: parameters,
      name: name,
      originFilePath: filePath,
    );

    return rawWidgetDj;
  }

  List<Parameter> processParameterLines(
    List<String> parameterLines, {
    bool intialIsOptional = false,
  }) {
    var debuggingLines = fileDebugLvl > 0;
    var parameters = <Parameter>[];

    if (debuggingLines) {
      print('intialIsOptional: $intialIsOptional');
    }

    var isOptional = intialIsOptional;
    var skipLines = 0;
    parameterLines.forEach((parameterLine) {
      // Use this when debugging parsing of a particular line.
      // if ((skipLines == 0)) {
      //   print('');
      //   print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
      //   print('$currentConstructorName @ $currentFileName');
      //   print('$parameterLine');
      //   debuggingLines = true;
      // }

      // var line = parameterLine.split('    ').last;
      var line = WhiteSpaceRemover(line: parameterLine).removeFromStart();

      if (debuggingLines) {
        print('1. $line');
      }

      // Indicates if we should just this line ?
      var skipOnlyThisLine = false;

      // This means that this is a modifier and not a field
      // so we should just skip it
      if (line.startsWith('@')) {
        skipOnlyThisLine = true;
      }

      // This means that this is start of a Multi-Line object initialization
      // so we should start skipping lines until this initialization ends.
      if (line.endsWith('(')) {
        skipLines += 1;
      }

      if ((skipLines == 0) || skipOnlyThisLine) {
        if (line.endsWith(',') || line.endsWith(', {')) {
          var _isOptional = isOptional;
          if (line.endsWith(', {')) {
            // This means that all fields after this will be optional to specify
            isOptional = true;
            line = line.split(', {').first;
          } else {
            line = line.substring(0, line.length - 1);
          }

          if (debuggingLines) {
            print('1.5. $line [$_isOptional]');
          }

          if (debuggingLines) {
            print('2. $line');
          }

          var defaultValue;

          var lineParts = line.split('=');
          if (lineParts.length == 2) {
            defaultValue =
                WhiteSpaceRemover(line: lineParts.last).removeFromStart();
            line = WhiteSpaceRemover(line: lineParts.first).removeFromEnd();
          }

          if (debuggingLines) {
            print('3. $line [$defaultValue]');
          }

          // Extract 'required'
          var isRequired = line.startsWith('required');
          line = line.split('required ').last;

          if (debuggingLines) {
            print('4. $line [$isRequired]');
          }

          // Determine if it's final type field
          var isFinal = line.contains('this.');
          line = line.replaceAll('this.', '');

          if (debuggingLines) {
            print('5. $line [$isFinal]');
          }

          if (line.contains('[') && line.contains(']')) {
            var lineBefore = line;
            line = line.replaceAll('[', '').replaceAll(']', '');
            line = WhiteSpaceRemover(line: line).remove();

            _isOptional = true;
            isRequired = false;
            isFinal = true;

            if (debuggingLines) {
              print('5.5. $lineBefore => $line');
            }
          }

          lineParts = line.split(' ');

          late String name;
          late String? type;
          if (lineParts.length > 1) {
            name = line.split(' ').last;
            type = line.split(' $name').first;
          } else {
            name = line;
            type = null;
          }
          // if (line.split(' ').length == 2) {
          //   lineParts = line.split(' ');
          //   type = lineParts.first;
          //   line = lineParts.last;
          // }

          if (debuggingLines) {
            print('6. [$type] [$name]');
          }

          var parameter = Parameter(
            isFinal: isFinal,
            name: name,
            type: type,
            isOptional: _isOptional,
            defaultValue: defaultValue,
            isRequired: isRequired,
            rawLine: parameterLine,
          );

          // print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
          // print('$parameterLine');
          // print('$parameter');
          // print('');

          parameters.add(parameter);
        }
      }

      // detects last of skipping lines.
      if (skipLines > 0) {
        if (line == '},') {
          skipLines -= 1;
        }
        if (line == '),') {
          skipLines -= 1;
        }
      }
    });

    return parameters;
  }
}
