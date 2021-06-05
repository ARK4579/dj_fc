import 'white_space_remover.dart';

bool isSingleLineComment(String line) {
  return WhiteSpaceRemover(line: line).removeFromStart().startsWith('//');
}

List<String> removeComments(List<String> lines) {
  return lines.where((c) => !isSingleLineComment(c)).toList();
}
