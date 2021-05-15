class WhiteSpaceRemover {
  final String line;
  WhiteSpaceRemover({
    required this.line,
  });

  String removeFromStart() {
    var removedLine = '';

    var characterHit = false;
    for (var i = 0; i < line.length; i++) {
      if (!characterHit && line[i] != ' ') {
        characterHit = true;
      }
      if (characterHit) {
        removedLine += line[i];
      }
    }

    return removedLine;
  }

  String removeFromEnd() {
    var removedLine = '';

    var characterHit = false;
    for (var i = line.length - 1; i >= 0; i--) {
      if (!characterHit && line[i] != ' ') {
        characterHit = true;
      }
      if (characterHit) {
        removedLine = line[i] + removedLine;
      }
    }

    return removedLine;
  }
}
