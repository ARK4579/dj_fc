import 'package:dj_io/dj_io.dart';
import 'package:recase/recase.dart';

import 'parameter.dart';

class _SafetyDataType {
  final String? dataType;
  final List<String>? description;
  _SafetyDataType({
    required this.dataType,
    this.description,
  });
}

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

  static List<String> unKnownDataTypes = [];

  //
  // Getters
  //

  String get widgetDjName => name + 'Dj';

  //
  // Functions
  //

  List<CodePartDj> _fieldImportDjs(
    List<FieldDj> fields,
    Map<String, String> djNamesMap,
  ) {
    var _fieldImportDjs = <CodePartDj>[];

    fields.forEach((field) {
      if (djNamesMap.keys.contains(field.dataType)) {
        var fieldName = field.dataType!;
        fieldName = fieldName.replaceAll('?', '');
        fieldName = fieldName.replaceAll('List<', '');
        fieldName = fieldName.replaceAll('>', '');
        var fieldWidgetFileName = ReCase(fieldName + 'Dj').snakeCase;
        _fieldImportDjs.add(
          ImportDj(importStr: fieldWidgetFileName, isFile: true),
        );
      }
    });

    return _fieldImportDjs;
  }

  _SafetyDataType _getFieldSafeDataType(
    Parameter parameter,
    Map<String, String> djNamesMap,
  ) {
    var dataType = parameter.type;
    if (dataType == null) return _SafetyDataType(dataType: null);

    return _SafetyDataType(dataType: 'dynamic', description: [
      "// Setting data type of this field to be 'dynamic' instead of",
      "// '$dataType' for now.",
    ]);

    // var hasDefaultValue = parameter.defaultValue != null;

    // if (dataType != 'dynamic' &&
    //     !djNamesMap.keys.contains(dataType) &&
    //     !dataType.contains('<')) {
    //   if (!unKnownDataTypes.contains(dataType)) {
    //     unKnownDataTypes.add(dataType);
    //   }
    // }

    // var lines;
    // var dataTypeLine = 'dynamic';
    // var mappedDataType = djNamesMap[dataType];
    // if (dataType.contains('<')) {
    //   lines = ['// $dataType Because Generics are not handled yet'];
    // } else if (mappedDataType == null) {
    //   lines = ["// $dataType Because it's Dj Version Not implemented yet"];
    // } else if (hasDefaultValue) {
    //   lines = ['// $dataType because Non-Dj default value is provided.'];
    // } else if (!dataType.endsWith('?') && !parameter.isFieldRequired) {
    //   lines = ["// $dataType because for default value couldn't parsed."];
    // } else {
    //   dataTypeLine = mappedDataType;
    // }

    // if (lines != null) {
    //   var r = "// Setting data type of this field to be 'dynamic' instead of";
    //   lines = [r] + lines;
    // }

    // return _SafetyDataType(dataType: dataTypeLine, description: lines);
  }

  CodePartDj getToCode(List<FieldDj> fields) {
    var bodyCodeLines = <String>["codeLines.add('$name( '); "];
    fields.forEach((field) {
      if (field.name != 'baseWidgetDjType' &&
          !(field.name?.startsWith('_') ?? false)) {
        bodyCodeLines.add('if(${field.name} != null) { ');
        var fieldValue = '\${dynamicParameterParser(${field.name})}';
        if (field.isOptional ?? false) {
          bodyCodeLines.add("codeLines.add('${field.name} : $fieldValue, '); ");
        } else {
          bodyCodeLines.add("codeLines.add('$fieldValue, '); ");
        }
        bodyCodeLines.add('}');
      }
    });
    bodyCodeLines.add("codeLines.add(') '); ");

    List<CodePartDj>? bodyCodeParts = [
      VariableDeclarationDj(
        dataType: VariableType.Var,
        name: 'codeLines',
        initialValue: '<String>[]',
      ),
    ];
    bodyCodeParts += bodyCodeLines.map((e) => SingleLineDj(line: e)).toList();
    bodyCodeParts.add(
      ReturnDj(
        returnStr: 'codeLines',
      ),
    );

    CodePartDj codePartDj = FunctionDj(
      annotations: ['override'],
      outputType: VariableType.ListString,
      name: 'toCode',
      bodyCodeParts: bodyCodeParts,
    );

    return codePartDj;
  }

  CodePartDj getToString() {
    CodePartDj codePartDj = FunctionDj(
      annotations: ['override'],
      outputType: VariableType.String,
      name: 'toString',
      bodyCodeParts: [
        ReturnDj(returnStr: "toCode().join('')"),
      ],
    );

    return codePartDj;
  }

  FileDj? toWidgetDjFileDj(Map<String, String> djNamesMap) {
    var widgetFileName = ReCase(widgetDjName).snakeCase;

    var fields = parameters
        .map(
          (p) => FieldDj(
            name: p.name,
            dataType: p.type,
            safeDataType: _getFieldSafeDataType(p, djNamesMap).dataType,
            safetyDescription: _getFieldSafeDataType(p, djNamesMap).description,
            isFinal: p.isFinal,
            isRequired: p.isFieldRequired,
            isOptional: p.isOptional,
            defaultValue: p.defaultValue,
          ),
        )
        .toList();

    fields.add(
      FieldDj(
        name: 'baseWidgetDjType',
        dataType: 'String',
        defaultValue: "'$name'",
        superOnly: true,
      ),
    );

    var codeParts = <CodePartDj>[
      ImportDj(importStr: 'dj', isPackage: true),
      ImportDj(importStr: 'json_annotation', isPackage: true),
      EmptyLineDj(),
      ImportDj(importStr: widgetFileName, isPart: true),
      EmptyLineDj(),
      ClassDj(
        name: widgetDjName,
        isExtends: true,
        baseName: 'BaseWidgetDj',
        fields: fields,
        jsonSerializable: true,
        functions: [
          getToCode(fields),
          getToString(),
        ],
      ),
      EmptyLineDj(),
    ];

    // since we are setting all types to dynamic, we don't have to import
    // codeParts += _fieldImportDjs(fields, djNamesMap);

    var widgetDjCodeFileDj = FileDj(
      name: widgetFileName,
      codeParts: codeParts,
    );

    return widgetDjCodeFileDj;
  }
}
