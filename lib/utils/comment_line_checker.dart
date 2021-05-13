class CommentLineChecker {
  final String line;

  CommentLineChecker({
    required this.line,
  });

  bool check() {
    for (var i = 0; i < line.length - 1; i++) {
      if (line[i] == '/' && line[i + 1] == '/') {
        return true;
      } else if (line[i] != ' ') {
        return false;
      }
    }
    return false;
  }
}
