import 'dart:io';

import 'package:recase/recase.dart';

import '../models/models.dart';
import '../utils/utils.dart';

class WidgetFileProcessor {
  final FileSystemEntity file;

  WidgetFileProcessor({
    required this.file,
  });

  List<RawWidgetDj> process() {
    var rawWidgetDjs = <RawWidgetDj>[];

    var itemPath = file.uri.toFilePath();
    var widgetNameSC = itemPath.split('\\').last.split('.dart').first;
    var widgetNamePC = ReCase(widgetNameSC).pascalCase;

    var fileHandler = File(itemPath);

    var fileLines = fileHandler.readAsLinesSync().toList();

    var parameterLines = <String>[];

    // 0 => Not Found Yet
    // 1 => Constructor comments running
    // 2 => Constructor
    // 2 => After Constructor
    var constructorFound = 0;
    fileLines.forEach((line) {
      if (constructorFound == 0 &&
          (line.contains('class $widgetNamePC extends ') ||
              line.contains('class $widgetNamePC<T> extends ') ||
              line.contains(
                  'class $widgetNamePC<T extends Object?> extends '))) {
        constructorFound = 1;
      } else if (constructorFound == 1 && !line.startsWith('  ///')) {
        constructorFound = 2;
      } else if (constructorFound == 2 && line.isEmpty) {
        constructorFound = 3;
      }

      if (constructorFound == 2) {
        parameterLines.add(line);
      }
    });

    rawWidgetDjs.add(processWidgetParams(widgetNamePC, parameterLines));

    return rawWidgetDjs;
  }

  RawWidgetDj processWidgetParams(String name, List<String> lines) {
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

    var rawWidgetDj = RawWidgetDj(parameters: parameters, name: name);

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
