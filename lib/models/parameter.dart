class Parameter {
  final String? type;
  final bool isFinal;
  final String name;
  final String? defaultValue;
  final bool isOptional;
  final bool isRequired;
  final String rawLine;

  Parameter({
    this.type,
    required this.isFinal,
    required this.name,
    this.defaultValue,
    required this.isOptional,
    required this.isRequired,
    required this.rawLine,
  });

  @override
  String toString() {
    var str = 'type: $type, ';
    str += 'isFinal: $isFinal, ';
    str += 'name: $name, ';
    str += 'default: $defaultValue, ';
    str += 'isOptional: $isOptional, ';
    str += 'isRequired: $isRequired, ';
    str += 'rawLine: $rawLine, ';
    return str;
  }

  //
  // Getters
  //

  bool get isFieldRequired => (isRequired || isFinal) && !isOptional;
}
