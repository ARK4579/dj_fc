import 'package:dj_io/dj_io.dart';
import 'package:recase/recase.dart';

import 'parameter.dart';

class RawWidgetDj {
  final String name;
  final List<Parameter> parameters;
  final String originFilePath;

  RawWidgetDj({
    required this.name,
    required this.parameters,
    required this.originFilePath,
  });

  @override
  String toString() {
    return name + '\n' + parameters.map((e) => '>>>${e.toString()}').join('\n');
  }

  //
  // Getters
  //

  String get widgetDjName => name + 'Dj';

  //
  // Functions
  //

  List<CodePartDj> _fieldImportDjs(List<FieldDj> fields) {
    var _fieldImportDjs = <CodePartDj>[];

    fields.forEach((field) {
      if (djNamesMap.keys.contains(field.dataType)) {
        var fieldName = field.dataType!.replaceAll('?', '');
        var fieldWidgetFileName = ReCase(fieldName + 'Dj').snakeCase;
        _fieldImportDjs.add(
          ImportDj(importStr: fieldWidgetFileName, isFile: true),
        );
      }
    });

    return _fieldImportDjs;
  }

  FileDj? toWidgetDjFileDj() {
    // if (parameters.isEmpty) return null;

    var widgetFileName = ReCase(widgetDjName).snakeCase;

    var fields = parameters
        .map(
          (p) => FieldDj(
            name: p.name,
            dataType: p.type,
            isFinal: p.isFinal,
            // isRequired: p.isRequired,
            isRequired: (p.isRequired || p.isFinal) && !p.isOptional,
            isOptional: p.isOptional,
            defaultValue: p.defaultValue,
          ),
        )
        .toList();

    fields.add(
      FieldDj(
        name: 'baseWidgetDjType',
        dataType: 'WidgetDjTypes',
        defaultValue: 'WidgetDjTypes.$name',
        superOnly: true,
      ),
    );

    var widgetDjCodeFileDj = FileDj(
      name: widgetFileName,
      codeParts: _fieldImportDjs(fields) +
          [
            ImportDj(importStr: 'json_annotation', isPackage: true),
            ImportDj(importStr: 'foundation', isFlutter: true),
            ImportDj(importStr: 'widgets', isFlutter: true),
            ImportDj(importStr: '../widget_dj_types', isFile: true),
            ImportDj(importStr: '../base_widget_dj', isFile: true),
            ImportDj(importStr: widgetFileName, isPart: true),
            ClassDj(
              name: widgetDjName,
              isExtends: true,
              baseName: 'BaseWidgetDj',
              fields: fields,
              jsonSerializable: true,
            ),
          ],
    );

    return widgetDjCodeFileDj;
  }
}
