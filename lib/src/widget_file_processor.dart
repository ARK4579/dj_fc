import 'dart:io';

import '../models/models.dart';
import '../utils/utils.dart';

class WidgetFileProcessor {
  final FileSystemEntity file;

  WidgetFileProcessor({
    required this.file,
  });

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

    var fileHandler = File(itemPath);

    var fileLines = fileHandler.readAsLinesSync().toList();

    var parameterLines = <String>[];

    // 0 => Not Found Yet
    // 1 => Constructor comments running
    // 2 => Constructor
    // 3 => After Constructor
    var constructorFound = 0;
    String? constructorName;
    fileLines.forEach((line) {
      var _constructorName = _isConstructorLine(line);
      if (constructorFound == 0 && _constructorName != null) {
        constructorName = _constructorName;
        constructorFound = 1;
      } else if (constructorFound == 1 && !line.startsWith('  ///')) {
        constructorFound = 2;
      } else if (constructorFound == 2 && line.isEmpty) {
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

      if (constructorFound == 2) {
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
        if (line.contains(') :') ||
            line.contains(');') ||
            line.contains(': assert')) {
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
    var skipLine = false;
    parameterLines.forEach((parameterLine) {
      var _line = parameterLine.split('    ').last;

      if (_line.startsWith('@') || _line.endsWith('(')) {
        skipLine = true;
      }

      if (!skipLine) {
        if (_line.endsWith(',') || _line.endsWith(', {')) {
          var endingWith = _line.endsWith(',') ? ',' : ', {';
          var __line = _line.split(endingWith).first;

          var defaultValue;

          var __lineSplit = __line.split(' = ');
          if (__lineSplit.length == 2) {
            defaultValue = __lineSplit.last;
            __line = __lineSplit.first;
          }

          var isRequired = _line.startsWith('required');
          __line = __line.split('required ').last;

          var isFinal = _line.contains('this.');
          __line = __line.replaceAll('this.', '');

          var type;
          if (__line.split(' ').length == 2) {
            __lineSplit = __line.split(' ');
            type = __lineSplit.first;
            __line = __lineSplit.last;
          }

          var parameter = Parameter(
            isFinal: isFinal,
            name: __line,
            type: type,
            isOptional: isOptional,
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

        if (_line.endsWith(', {')) {
          isOptional = true;
        }
      }

      if (skipLine) {
        if (_line == '},') {
          skipLine = false;
        }
        if (_line == '),') {
          skipLine = false;
        }
      }
    });

    return parameters;
  }
}
