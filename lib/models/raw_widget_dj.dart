import 'package:dj_io/dj_io.dart';
import 'package:recase/recase.dart';

import 'parameter.dart';

class RawWidgetDj {
  final String name;
  final List<Parameter> parameters;

  RawWidgetDj({
    required this.name,
    required this.parameters,
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

  FileDj? toWidgetDjFileDj() {
    if (parameters.isEmpty) return null;

    var widgetFileName = ReCase(widgetDjName).snakeCase;

    var fields = parameters
        .map(
          (p) => FieldDj(
            name: p.name,
            dataType: p.type,
            isFinal: p.isFinal,
            isRequired: (p.isRequired || p.isFinal) && !p.isOptional,
          ),
        )
        .toList();

    fields.add(
      FieldDj(
        name: 'type',
        dataType: 'WidgetDjTypes',
        defaultValue: 'WidgetDjTypes.$name',
        constructorOnly: true,
      ),
    );

    var widgetDjCodeFileDj = FileDj(
      name: widgetFileName,
      codeParts: [
        ImportDj(importStr: 'json_annotation', isPackage: true),
        ImportDj(importStr: 'foundation', isFlutter: true),
        ImportDj(importStr: 'widgets', isFlutter: true),
        ImportDj(importStr: '../widget_dj_types', isFile: true),
        ImportDj(importStr: '../widget_dj', isFile: true),
        ImportDj(importStr: widgetFileName, isPart: true),
        ClassDj(
          name: widgetDjName,
          isExtends: true,
          baseName: 'WidgetDj',
          fields: fields,
          jsonSerializable: true,
        ),
      ],
    );

    return widgetDjCodeFileDj;
  }
}
