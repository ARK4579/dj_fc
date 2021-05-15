import 'dart:io';

import '../models/models.dart';
import '../utils/utils.dart';

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
        if (matchString != null) {
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
    fileLines.forEach((line) {
      var parsedLine = WhiteSpaceRemover(line: line).removeFromStart();
      var _constructorName = _isConstructorLine(line);
      if (constructorFound == 0 && _constructorName != null) {
        constructorName = _constructorName;
        constructorFound = 1;
        constructorLess = false;
        currentConstructorName = constructorName!;
      } else if (constructorFound == 1 && !parsedLine.startsWith('///')) {
        constructorFound = 2;
        constructorLess = !line.contains(constructorName!) ||
            line.contains('super') ||
            (line.endsWith('{') && line.contains(')'));
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
          ),
        );

        parameterLines = [];
        constructorName = null;
      }

      if (constructorFound == 2 && !constructorLess) {
        parameterLines.add(line);
      }
    });

    return rawWidgetDjs;
  }

  RawWidgetDj processWidgetParams(
      String name, List<String> lines, String filePath) {
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

    var parameters = processParameterLines(parameterLines);

    var rawWidgetDj = RawWidgetDj(
      parameters: parameters,
      name: name,
      originFilePath: filePath,
    );

    return rawWidgetDj;
  }

  List<Parameter> processParameterLines(List<String> parameterLines) {
    var parameters = <Parameter>[];

    var isOptional = false;
    var skipLines = 0;
    parameterLines.forEach((parameterLine) {
      // Use this when debugging parsing of a particular line.
      var debuggingThisLine = false;
      // if ((skipLines == 0) && !parameterLine.contains('(')) {
      //   print('');
      //   print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
      //   print('$currentConstructorName @ $currentFileName');
      //   print('$parameterLine');
      //   debuggingThisLine = true;
      // }

      // var line = parameterLine.split('    ').last;
      var line = WhiteSpaceRemover(line: parameterLine).removeFromStart();

      if (debuggingThisLine) {
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

          if (debuggingThisLine) {
            print('1.5. $line [$isOptional]');
          }

          if (debuggingThisLine) {
            print('2. $line');
          }

          var defaultValue;

          var lineParts = line.split('=');
          if (lineParts.length == 2) {
            defaultValue =
                WhiteSpaceRemover(line: lineParts.last).removeFromStart();
            line = WhiteSpaceRemover(line: lineParts.first).removeFromEnd();
          }

          if (debuggingThisLine) {
            print('3. $line [$defaultValue]');
          }

          // Extract 'required'
          var isRequired = line.startsWith('required');
          line = line.split('required ').last;

          if (debuggingThisLine) {
            print('4. $line [$isRequired]');
          }

          // Determine if it's final type field
          var isFinal = line.contains('this.');
          line = line.replaceAll('this.', '');

          if (debuggingThisLine) {
            print('5. $line [$isFinal]');
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

          if (debuggingThisLine) {
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
