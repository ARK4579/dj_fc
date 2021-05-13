import 'parameter.dart';

class RawWidgetDj {
  final List<Parameter> parameters;
  final String name;

  RawWidgetDj({
    required this.parameters,
    required this.name,
  });

  @override
  String toString() {
    return name + '\n' + parameters.map((e) => '>>>${e.toString()}').join('\n');
  }
}
